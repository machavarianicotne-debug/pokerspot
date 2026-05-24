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
  }) async {
    final doc = await _tables(clubId).add({
      'number': number,
      ...stakes.toMap(),
      'seatCount': seatCount,
      'open': open,
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
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) {
    return _col.add({
      'clubId': clubId,
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
    return Session.fromMap(d.id, m);
  }

  @override
  Stream<List<Session>> watchActiveByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs
          .map(_session)
          .where((x) => x.status == SessionStatus.active)
          .toList());

  @override
  Stream<List<Session>> watchAllByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_session).toList());

  @override
  Stream<List<Session>> watchByPlayer(String playerUid) => _col
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs
          .map(_session)
          .where((x) => x.status == SessionStatus.active)
          .toList());

  @override
  Future<void> seatWalkIn({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerName,
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'seatNumber': seatNumber,
      'playerUid': 'walk-in:${DateTime.now().microsecondsSinceEpoch}',
      'playerName': playerName,
      ...stakes.toMap(),
      'status': SessionStatus.active.asString,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });
  }

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
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) {
    return _col.add({
      'clubId': clubId,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': ReservationStatus.held.asString,
      // 30-minute hold; a Cloud Function expires it (Wave 6).
      'heldUntil': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
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
