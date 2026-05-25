import 'dart:async';

import 'package:pokerspot/features/floor/domain/floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

/// Shared in-memory "database" so the three fake repos see each other's writes
/// (mirrors one Firestore project with multiple collections). Each [watch]
/// replays the current view on subscribe (sync), then re-emits on every
/// mutation. No Firebase imports.
class FakeFloorStore {
  FakeFloorStore({
    List<PokerTable>? tables,
    List<WaitlistEntry>? waitlist,
    List<Session>? sessions,
  }) {
    for (final t in tables ?? const <PokerTable>[]) {
      this.tables[t.id] = t;
    }
    for (final e in waitlist ?? const <WaitlistEntry>[]) {
      this.waitlist[e.id] = e;
    }
    for (final s in sessions ?? const <Session>[]) {
      this.sessions[s.id] = s;
    }
  }

  final tables = <String, PokerTable>{};
  final waitlist = <String, WaitlistEntry>{};
  final sessions = <String, Session>{};
  final reservations = <String, Reservation>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  String nextId(String prefix) => '$prefix-${_seq++}';
  void notify() => _changes.add(null);

  Stream<T> watch<T>(T Function() read) {
    final out = StreamController<T>();
    StreamSubscription<void>? sub;
    out.onListen = () {
      out.add(read());
      sub = _changes.stream.listen((_) => out.add(read()));
    };
    out.onCancel = () async {
      await sub?.cancel();
    };
    return out.stream;
  }
}

bool _activeEntry(WaitlistEntry e) =>
    e.status == WaitlistStatus.waiting || e.status == WaitlistStatus.called;

int _byCreated(WaitlistEntry a, WaitlistEntry b) =>
    (a.createdAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(b.createdAt?.millisecondsSinceEpoch ?? 0);

class FakeTablesRepository implements TablesRepository {
  FakeTablesRepository(this.store);
  final FakeFloorStore store;

  @override
  Stream<List<PokerTable>> watchTables(String clubId) => store.watch(() =>
      store.tables.values.where((t) => t.clubId == clubId).toList()
        ..sort((a, b) => a.number.compareTo(b.number)));

  @override
  Future<String> createTable({
    required String clubId,
    required int number,
    required Stakes stakes,
    required int seatCount,
    required bool open,
    num? avgStack,
    num? minBuyIn,
  }) async {
    final id = store.nextId('table');
    store.tables[id] = PokerTable(
      id: id,
      clubId: clubId,
      number: number,
      stakes: stakes,
      seatCount: seatCount,
      open: open,
      avgStack: avgStack,
      minBuyIn: minBuyIn,
    );
    store.notify();
    return id;
  }

  @override
  Future<void> updateTable(PokerTable table) async {
    store.tables[table.id] = table;
    store.notify();
  }

  @override
  Future<void> deleteTable({required String clubId, required String tableId}) async {
    store.tables.remove(tableId);
    store.notify();
  }
}

class FakeWaitlistRepository implements WaitlistRepository {
  FakeWaitlistRepository(this.store);
  final FakeFloorStore store;

  @override
  Stream<List<WaitlistEntry>> watchByClub(String clubId) => store.watch(() =>
      store.waitlist.values
          .where((e) => e.clubId == clubId && _activeEntry(e))
          .toList()
        ..sort(_byCreated));

  @override
  Stream<List<WaitlistEntry>> watchByPlayer(String playerUid) => store.watch(() =>
      store.waitlist.values
          .where((e) => e.playerUid == playerUid && _activeEntry(e))
          .toList()
        ..sort(_byCreated));

  @override
  Future<void> join({
    required String clubId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) async {
    final id = store.nextId('wl');
    store.waitlist[id] = WaitlistEntry(
      id: id,
      clubId: clubId,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: WaitlistStatus.waiting,
      createdAt: DateTime.now(),
      calledAt: null,
    );
    store.notify();
  }

  @override
  Future<void> cancel(String entryId) async {
    final e = store.waitlist[entryId];
    if (e != null) {
      store.waitlist[entryId] = e.copyWith(status: WaitlistStatus.cancelled);
      store.notify();
    }
  }

  @override
  Future<void> call(String entryId) async {
    final e = store.waitlist[entryId];
    if (e != null) {
      store.waitlist[entryId] =
          e.copyWith(status: WaitlistStatus.called, calledAt: DateTime.now());
      store.notify();
    }
  }

  @override
  Future<void> seat({
    required WaitlistEntry entry,
    required String tableId,
    required int seatNumber,
  }) async {
    store.waitlist[entry.id] = entry.copyWith(status: WaitlistStatus.seated);
    final id = store.nextId('session');
    store.sessions[id] = Session(
      id: id,
      clubId: entry.clubId,
      tableId: tableId,
      seatNumber: seatNumber,
      playerUid: entry.playerUid,
      playerName: entry.playerName,
      stakes: entry.stakes,
      status: SessionStatus.active,
      startedAt: DateTime.now(),
      endedAt: null,
    );
    store.notify();
  }
}

bool _heldRes(Reservation r) => r.status == ReservationStatus.held;

class FakeReservationsRepository implements ReservationsRepository {
  FakeReservationsRepository(this.store);
  final FakeFloorStore store;

  @override
  Stream<List<Reservation>> watchByPlayer(String playerUid) => store.watch(() => store
      .reservations.values
      .where((r) => r.playerUid == playerUid && _heldRes(r))
      .toList());

  @override
  Stream<List<Reservation>> watchByClub(String clubId) => store.watch(() => store
      .reservations.values
      .where((r) => r.clubId == clubId && _heldRes(r))
      .toList());

  @override
  Future<void> reserve({
    required String clubId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) async {
    final id = store.nextId('res');
    store.reservations[id] = Reservation(
      id: id,
      clubId: clubId,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: ReservationStatus.held,
      heldUntil: DateTime.now().add(const Duration(minutes: 30)),
      createdAt: DateTime.now(),
    );
    store.notify();
  }

  @override
  Future<void> cancel(String reservationId) async {
    final r = store.reservations[reservationId];
    if (r != null) {
      store.reservations[reservationId] = r.copyWith(status: ReservationStatus.cancelled);
      store.notify();
    }
  }

  @override
  Future<void> markArrived(String reservationId) async {
    final r = store.reservations[reservationId];
    if (r != null) {
      store.reservations[reservationId] = r.copyWith(status: ReservationStatus.arrived);
      store.notify();
    }
  }
}

class FakeSessionsRepository implements SessionsRepository {
  FakeSessionsRepository(this.store);
  final FakeFloorStore store;

  static bool _open(Session s) =>
      s.status == SessionStatus.active || s.status == SessionStatus.held;

  @override
  Stream<List<Session>> watchActiveByClub(String clubId) => store.watch(() =>
      store.sessions.values.where((s) => s.clubId == clubId && _open(s)).toList());

  @override
  Stream<List<Session>> watchAllByClub(String clubId) => store.watch(() =>
      store.sessions.values.where((s) => s.clubId == clubId).toList());

  @override
  Stream<List<Session>> watchByPlayer(String playerUid) => store.watch(() =>
      store.sessions.values.where((s) => s.playerUid == playerUid && _open(s)).toList());

  @override
  Stream<List<Session>> watchAllByPlayer(String playerUid) => store.watch(() =>
      store.sessions.values.where((s) => s.playerUid == playerUid).toList());

  @override
  Future<void> seatWalkIn({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerName,
  }) =>
      seatPlayer(
        clubId: clubId,
        tableId: tableId,
        seatNumber: seatNumber,
        stakes: stakes,
        playerUid: 'walk-in:${store.nextId('w')}',
        playerName: playerName,
      );

  @override
  Future<void> seatPlayer({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerUid,
    required String playerName,
  }) async {
    final id = store.nextId('session');
    store.sessions[id] = Session(
      id: id,
      clubId: clubId,
      tableId: tableId,
      seatNumber: seatNumber,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: SessionStatus.active,
      startedAt: DateTime.now(),
      endedAt: null,
    );
    store.notify();
  }

  @override
  Future<void> holdSeat({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerUid,
    required String playerName,
    required String holdKind,
    required int durationMinutes,
  }) async {
    final id = store.nextId('session');
    store.sessions[id] = Session(
      id: id,
      clubId: clubId,
      tableId: tableId,
      seatNumber: seatNumber,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: SessionStatus.held,
      startedAt: null,
      endedAt: null,
      holdKind: holdKind,
      heldUntil: DateTime.now().add(Duration(minutes: durationMinutes)),
    );
    store.notify();
  }

  @override
  Future<void> seatFromHold(String sessionId) async {
    final s = store.sessions[sessionId];
    if (s != null) {
      store.sessions[sessionId] = Session(
        id: s.id, clubId: s.clubId, tableId: s.tableId, seatNumber: s.seatNumber,
        playerUid: s.playerUid, playerName: s.playerName, stakes: s.stakes,
        status: SessionStatus.active, startedAt: DateTime.now(), endedAt: null,
      );
      store.notify();
    }
  }

  @override
  Future<void> releaseHold(String sessionId) => end(sessionId);

  @override
  Future<void> end(String sessionId) async {
    final s = store.sessions[sessionId];
    if (s != null) {
      store.sessions[sessionId] =
          s.copyWith(status: SessionStatus.ended, endedAt: DateTime.now());
      store.notify();
    }
  }
}
