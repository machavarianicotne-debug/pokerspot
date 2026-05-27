import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

PokerTable _table(String id, String clubId, int number) => PokerTable(
      id: id, clubId: clubId, number: number, stakes: _stakes, seatCount: 9, open: true);

void main() {
  test('tables: watchTables filters by club, sorted by number', () async {
    final store = FakeFloorStore(tables: [
      _table('t2', 'c1', 2),
      _table('t1', 'c1', 1),
      _table('tx', 'c2', 1),
    ]);
    final list = await FakeTablesRepository(store).watchTables('c1').first;
    expect(list.map((t) => t.id), ['t1', 't2']);
  });

  test('tables: create -> update -> delete round-trips through the store', () async {
    final store = FakeFloorStore();
    final repo = FakeTablesRepository(store);

    final id = await repo.createTable(
        clubId: 'c1', number: 3, stakes: _stakes, seatCount: 9, open: true);
    var list = await repo.watchTables('c1').first;
    expect(list.length, 1);
    expect(list.first.number, 3);

    await repo.updateTable(list.first.copyWith(open: false, seatCount: 6));
    list = await repo.watchTables('c1').first;
    expect(list.first.open, isFalse);
    expect(list.first.seatCount, 6);

    await repo.deleteTable(clubId: 'c1', tableId: id);
    expect(await repo.watchTables('c1').first, isEmpty);
  });

  test('seatWalkIn: creates an active walk-in session (synthetic uid)', () async {
    final store = FakeFloorStore();
    final sessions = FakeSessionsRepository(store);

    await sessions.seatWalkIn(
        clubId: 'c1', tableId: 't1', seatNumber: 4, stakes: _stakes, playerName: 'Walk-in');
    final active = await sessions.watchActiveByClub('c1').first;
    expect(active.length, 1);
    expect(active.first.seatNumber, 4);
    expect(active.first.playerUid, startsWith('walk-in:'));
    expect(active.first.status, SessionStatus.active);
  });

  test('holdSeat -> seatFromHold: held seat occupies, then becomes active', () async {
    final store = FakeFloorStore();
    final sessions = FakeSessionsRepository(store);

    await sessions.holdSeat(
        clubId: 'c1', tableId: 't1', seatNumber: 3, stakes: _stakes,
        playerUid: 'u', playerName: 'Nino', holdKind: 'reservation', durationMinutes: 30);
    var open = await sessions.watchActiveByClub('c1').first;
    expect(open.length, 1); // held seats occupy a seat
    expect(open.first.status, SessionStatus.held);
    expect(open.first.holdKind, 'reservation');

    await sessions.seatFromHold(open.first.id);
    open = await sessions.watchActiveByClub('c1').first;
    expect(open.first.status, SessionStatus.active);
    expect(open.first.startedAt, isNotNull);
  });

  test('seatPlayer: seats a registered player keeping their real uid', () async {
    final store = FakeFloorStore();
    final sessions = FakeSessionsRepository(store);

    await sessions.seatPlayer(
        clubId: 'c1', tableId: 't1', seatNumber: 2, stakes: _stakes,
        playerUid: 'giorgi-uid', playerName: 'Giorgi M');
    // The seated player can see the session under their own uid (rules + activity).
    final mine = await sessions.watchByPlayer('giorgi-uid').first;
    expect(mine.length, 1);
    expect(mine.first.playerUid, 'giorgi-uid');
    expect(mine.first.playerName, 'Giorgi M');
    expect(mine.first.seatNumber, 2);
  });

  test('waitlist: join -> call -> cancel; by-club + by-player views', () async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);

    await wl.join(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', stakes: _stakes);
    var list = await wl.watchByClub('c1').first;
    expect(list.length, 1);
    expect(list.first.status, WaitlistStatus.waiting);

    final id = list.first.id;
    await wl.call(id);
    list = await wl.watchByClub('c1').first;
    expect(list.first.status, WaitlistStatus.called);
    expect(list.first.calledAt, isNotNull);

    expect((await wl.watchByPlayer('u1').first).length, 1);

    await wl.cancel(id);
    expect(await wl.watchByClub('c1').first, isEmpty);
    expect(await wl.watchByPlayer('u1').first, isEmpty);
  });

  test('seat: flips entry to seated + creates an active session', () async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    final sessions = FakeSessionsRepository(store);

    await wl.join(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', stakes: _stakes);
    final entry = (await wl.watchByClub('c1').first).first;

    await wl.seat(entry: entry, tableId: 't1', seatNumber: 5);

    expect(await wl.watchByClub('c1').first, isEmpty); // seated -> off the active list
    final secs = await sessions.watchActiveByClub('c1').first;
    expect(secs.length, 1);
    expect(secs.first.tableId, 't1');
    expect(secs.first.seatNumber, 5);
    expect(secs.first.playerUid, 'u1');
    expect(secs.first.status, SessionStatus.active);
  });

  test('reservations: reserve -> by-player + by-club; cancel/arrive drop it', () async {
    final store = FakeFloorStore();
    final res = FakeReservationsRepository(store);

    await res.reserve(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', stakes: _stakes, durationMinutes: 30);
    var mine = await res.watchByPlayer('u1').first;
    expect(mine.length, 1);
    expect(mine.first.status, ReservationStatus.held);
    expect(mine.first.heldUntil, isNotNull);
    expect((await res.watchByClub('c1').first).length, 1);

    final id = mine.first.id;
    await res.cancel(id);
    expect(await res.watchByPlayer('u1').first, isEmpty); // cancelled -> off the held list

    await res.reserve(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', stakes: _stakes, durationMinutes: 30);
    final id2 = (await res.watchByClub('c1').first).first.id;
    await res.markArrived(id2);
    expect(await res.watchByClub('c1').first, isEmpty); // arrived -> off the held list
  });

  test('sessions: end drops it from active (club + player views)', () async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    final sessions = FakeSessionsRepository(store);

    await wl.join(clubId: 'c1', playerUid: 'u1', playerName: 'N', stakes: _stakes);
    await wl.seat(entry: (await wl.watchByClub('c1').first).first, tableId: 't1', seatNumber: 1);
    final s = (await sessions.watchActiveByClub('c1').first).first;

    await sessions.end(s.id);
    expect(await sessions.watchActiveByClub('c1').first, isEmpty);
    expect(await sessions.watchByPlayer('u1').first, isEmpty);
  });

  test('watchByClub pushes live updates to an existing subscriber', () async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    final seen = <int>[];
    final sub = wl.watchByClub('c1').listen((l) => seen.add(l.length));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    await wl.join(clubId: 'c1', playerUid: 'u1', playerName: 'N', stakes: _stakes);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
