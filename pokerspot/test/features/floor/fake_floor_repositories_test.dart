import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
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
