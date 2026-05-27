import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/game_detail_screen.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

const _nlh = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'vake', number: 1, stakes: _nlh, seatCount: 9, open: true);

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  test('full waitlist lifecycle: join -> call -> seat -> end (shared store)', () async {
    final store = FakeFloorStore(tables: const [_table]);
    final auth = FakeAuthRepository();
    final s = await auth.sendOtp('+995555222222');
    await auth.confirmOtp(s, '222222');
    final uid = auth.currentUid!;

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      waitlistRepositoryProvider.overrideWithValue(FakeWaitlistRepository(store)),
      sessionsRepositoryProvider.overrideWithValue(FakeSessionsRepository(store)),
      tablesRepositoryProvider.overrideWithValue(FakeTablesRepository(store)),
    ]);
    addTearDown(container.dispose);

    // Keep the live providers active so they re-emit on every store mutation.
    final subs = [
      container.listen(clubWaitlistProvider('vake'), (_, __) {}),
      container.listen(myWaitlistProvider, (_, __) {}),
      container.listen(clubSessionsProvider('vake'), (_, __) {}),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });
    await _settle();

    final wl = container.read(waitlistRepositoryProvider);

    // Step 1 — player joins.
    await wl.join(clubId: 'vake', playerUid: uid, playerName: 'Nino', stakes: _nlh);
    await _settle();
    final waiting = container.read(clubWaitlistProvider('vake')).valueOrNull!;
    expect(waiting.length, 1);
    expect(waiting.first.status, WaitlistStatus.waiting);
    final entryId = waiting.first.id;

    // Step 2 — Pit Boss calls; the player's own view flips to called.
    await wl.call(entryId);
    await _settle();
    final mine = container.read(myWaitlistProvider).valueOrNull!;
    expect(mine.length, 1);
    expect(mine.first.status, WaitlistStatus.called);

    // Step 3 — Pit Boss seats: entry leaves the active waitlist, a session opens.
    final entry = container.read(clubWaitlistProvider('vake')).valueOrNull!.first;
    await wl.seat(entry: entry, tableId: 't1', seatNumber: 4);
    await _settle();
    expect(container.read(clubWaitlistProvider('vake')).valueOrNull, isEmpty);
    final sessions = container.read(clubSessionsProvider('vake')).valueOrNull!;
    expect(sessions.length, 1);
    expect(sessions.first.tableId, 't1');
    expect(sessions.first.seatNumber, 4);
    expect(sessions.first.playerUid, uid);

    // Step 4 — session ends: no active sessions remain.
    await container.read(sessionsRepositoryProvider).end(sessions.first.id);
    await _settle();
    expect(container.read(clubSessionsProvider('vake')).valueOrNull, isEmpty);
  });

  // Regression: seating a player from the *table-side* held-seat button must stop
  // the waitlist 'called' timer, exactly like the waitlist-side Seat button does.
  // Previously the table button only flipped the session active and left the
  // waitlist entry 'called' with its countdown still running.
  test('seatFromHeld: table-side Seat clears the called waitlist entry', () async {
    final store = FakeFloorStore(tables: const [_table]);
    final waitlistRepo = FakeWaitlistRepository(store);
    final sessionsRepo = FakeSessionsRepository(store);

    // Player joins, Pit calls -> entry 'called' + a 10-min held seat.
    await waitlistRepo.join(
        clubId: 'vake', playerUid: 'u1', playerName: 'Nino', stakes: _nlh);
    final entry = store.waitlist.values.first;
    await waitlistRepo.call(entry.id);
    await sessionsRepo.holdSeat(
        clubId: 'vake', tableId: 't1', seatNumber: 4, stakes: _nlh,
        playerUid: 'u1', playerName: 'Nino',
        holdKind: HoldKind.called, durationMinutes: 10);
    final held = store.sessions.values.firstWhere((s) => s.isHeld);
    expect(store.waitlist[entry.id]!.status, WaitlistStatus.called);

    // Seat from the table-side held-seat button.
    await GameDetailScreen.seatFromHeld(
      sessionsRepo: sessionsRepo,
      waitlistRepo: waitlistRepo,
      held: held,
      waitlist: store.waitlist.values.toList(),
    );

    // Session goes active AND the waitlist entry flips to seated (timer stops).
    expect(store.sessions[held.id]!.isActive, isTrue);
    expect(store.waitlist[entry.id]!.status, WaitlistStatus.seated);
  });

  // Deleting a table must end its open sessions, otherwise the player keeps
  // showing as "playing" at a table that no longer exists (orphaned session).
  test('deleteTableAndEndSessions ends the open sessions, then removes the table', () async {
    final store = FakeFloorStore(tables: const [_table]);
    final tablesRepo = FakeTablesRepository(store);
    final sessionsRepo = FakeSessionsRepository(store);

    final waitlistRepo = FakeWaitlistRepository(store);
    await sessionsRepo.seatWalkIn(
        clubId: 'vake', tableId: 't1', seatNumber: 1, stakes: _nlh, playerName: 'X');
    // A player waiting for the same stake — deleting the last table must clear them.
    await waitlistRepo.join(clubId: 'vake', playerUid: 'u9', playerName: 'Waiter', stakes: _nlh);
    final entry = store.waitlist.values.first;
    expect(store.sessions.values.where((s) => s.isActive).length, 1);

    await GameDetailScreen.deleteTableAndEndSessions(
      tablesRepo: tablesRepo,
      sessionsRepo: sessionsRepo,
      waitlistRepo: waitlistRepo,
      sessions: store.sessions.values.toList(),
      waitlistToCancel: store.waitlist.values.toList(), // last table → cancel the stake's waitlist
      clubId: 'vake',
      tableId: 't1',
    );

    expect(store.tables.containsKey('t1'), isFalse);
    expect(store.sessions.values.where((s) => s.isActive), isEmpty);
    expect(store.sessions.values.single.status, SessionStatus.ended);
    // The orphaned waitlist entry is cancelled (no longer "in the waitlist").
    expect(store.waitlist[entry.id]!.status, WaitlistStatus.cancelled);
  });
}
