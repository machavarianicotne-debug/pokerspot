import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/floor/domain/floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

/// Firestore Timestamp -> epoch millis (the domain models read millis). Passes
/// through ints/null so the pure-Dart models stay Firebase-free.
Object? _toMillis(Object? v) => v is Timestamp ? v.millisecondsSinceEpoch : v;

bool _activeEntry(WaitlistEntry e) =>
    e.status == WaitlistStatus.waiting || e.status == WaitlistStatus.called;

int _byCreated(WaitlistEntry a, WaitlistEntry b) =>
    (a.createdAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(b.createdAt?.millisecondsSinceEpoch ?? 0);

class FirebaseTablesRepository implements TablesRepository {
  FirebaseTablesRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tables(String clubId) =>
      _db.collection('clubs').doc(clubId).collection('tables');

  @override
  Stream<List<PokerTable>> watchTables(String clubId) => _tables(clubId)
      .snapshots()
      .map((s) => s.docs.map((d) => PokerTable.fromMap(d.id, clubId, d.data())).toList()
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
    final doc = await _tables(clubId).add({
      'number': number,
      ...stakes.toMap(),
      'seatCount': seatCount,
      'open': open,
      'avgStack': avgStack,
      'minBuyIn': minBuyIn,
    });
    return doc.id;
  }

  @override
  Future<void> updateTable(PokerTable table) =>
      _tables(table.clubId).doc(table.id).set(table.toMap());

  @override
  Future<void> deleteTable({required String clubId, required String tableId}) =>
      _tables(clubId).doc(tableId).delete();
}

class FirebaseWaitlistRepository implements WaitlistRepository {
  FirebaseWaitlistRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('waitlist');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sessions');

  WaitlistEntry _entry(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    m['createdAt'] = _toMillis(m['createdAt']);
    m['calledAt'] = _toMillis(m['calledAt']);
    return WaitlistEntry.fromMap(d.id, m);
  }

  // Filter status + sort client-side so only a single-field (clubId / playerUid)
  // index is needed — no composite Firestore indexes to provision for the MVP.
  @override
  Stream<List<WaitlistEntry>> watchByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_entry).where(_activeEntry).toList()..sort(_byCreated));

  @override
  Stream<List<WaitlistEntry>> watchByPlayer(String playerUid) => _col
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs.map(_entry).where(_activeEntry).toList()..sort(_byCreated));

  @override
  Future<void> join({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': WaitlistStatus.waiting.asString,
      'createdAt': FieldValue.serverTimestamp(),
      'calledAt': null,
    });
  }

  @override
  Future<void> cancel(String entryId) =>
      _col.doc(entryId).update({'status': WaitlistStatus.cancelled.asString});

  @override
  Future<void> call(String entryId) => _col.doc(entryId).update({
        'status': WaitlistStatus.called.asString,
        'calledAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> markSeated(String entryId) =>
      _col.doc(entryId).update({'status': WaitlistStatus.seated.asString});

  @override
  Future<void> seat({
    required WaitlistEntry entry,
    required String tableId,
    required int seatNumber,
  }) async {
    final batch = _db.batch();
    batch.set(_sessions.doc(), {
      'clubId': entry.clubId,
      'tableId': tableId,
      'seatNumber': seatNumber,
      'playerUid': entry.playerUid,
      'playerName': entry.playerName,
      ...entry.stakes.toMap(),
      'status': SessionStatus.active.asString,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });
    batch.update(_col.doc(entry.id), {'status': WaitlistStatus.seated.asString});
    await batch.commit();
  }
}

class FirebaseSessionsRepository implements SessionsRepository {
  FirebaseSessionsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('sessions');

  Session _session(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    m['startedAt'] = _toMillis(m['startedAt']);
    m['endedAt'] = _toMillis(m['endedAt']);
    // heldUntil is a Firestore Timestamp for held seats — convert it too, or
    // Session.fromMap's `millis as int` cast throws and the whole sessions
    // stream errors out (Pit floor + stats go blank whenever a held seat exists).
    m['heldUntil'] = _toMillis(m['heldUntil']);
    return Session.fromMap(d.id, m);
  }

  // "Open" = active OR held (both occupy a seat). Filter client-side so only a
  // single-field (clubId) index is needed.
  static bool _open(Session x) =>
      x.status == SessionStatus.active || x.status == SessionStatus.held;

  @override
  Stream<List<Session>> watchActiveByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_session).where(_open).toList());

  @override
  Stream<List<Session>> watchAllByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_session).toList());

  @override
  Stream<List<Session>> watchByPlayer(String playerUid) => _col
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs.map(_session).where(_open).toList());

  @override
  Stream<List<Session>> watchAllByPlayer(String playerUid) => _col
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs.map(_session).toList());

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
        playerUid: 'walk-in:${DateTime.now().microsecondsSinceEpoch}',
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
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'seatNumber': seatNumber,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': SessionStatus.active.asString,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });
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
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'seatNumber': seatNumber,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': SessionStatus.held.asString,
      'startedAt': null,
      'endedAt': null,
      'holdKind': holdKind,
      'heldUntil': Timestamp.fromDate(DateTime.now().add(Duration(minutes: durationMinutes))),
    });
  }

  @override
  Future<void> seatFromHold(String sessionId) => _col.doc(sessionId).update({
        'status': SessionStatus.active.asString,
        'startedAt': FieldValue.serverTimestamp(),
        'heldUntil': null,
        'holdKind': null,
      });

  @override
  Future<void> releaseHold(String sessionId) => _col.doc(sessionId).update({
        'status': SessionStatus.ended.asString,
        'endedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> end(String sessionId) => _col.doc(sessionId).update({
        'status': SessionStatus.ended.asString,
        'endedAt': FieldValue.serverTimestamp(),
      });
}

class FirebaseReservationsRepository implements ReservationsRepository {
  FirebaseReservationsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reservations');

  Reservation _res(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    m['heldUntil'] = _toMillis(m['heldUntil']);
    m['createdAt'] = _toMillis(m['createdAt']);
    return Reservation.fromMap(d.id, m);
  }

  bool _held(Reservation r) => r.status == ReservationStatus.held;

  @override
  Stream<List<Reservation>> watchByPlayer(String playerUid) => _col
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs.map(_res).where(_held).toList());

  @override
  Stream<List<Reservation>> watchByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_res).where(_held).toList());

  @override
  Future<void> reserve({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
    required int durationMinutes,
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': ReservationStatus.held.asString,
      'heldUntil': Timestamp.fromDate(DateTime.now().add(Duration(minutes: durationMinutes))),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancel(String reservationId) =>
      _col.doc(reservationId).update({'status': ReservationStatus.cancelled.asString});

  @override
  Future<void> markArrived(String reservationId) =>
      _col.doc(reservationId).update({'status': ReservationStatus.arrived.asString});
}
