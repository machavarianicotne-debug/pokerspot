import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
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
}
