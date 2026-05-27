import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournaments_repository.dart';

/// Firestore-backed tournaments. Flat `tournaments` collection; filter/sort
/// client-side so only a single-field (clubId) index is needed.
class FirebaseTournamentsRepository implements TournamentsRepository {
  FirebaseTournamentsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('tournaments');

  Tournament _t(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    final at = m['startAt'];
    m['startAt'] = at is Timestamp ? at.millisecondsSinceEpoch : at;
    return Tournament.fromMap(d.id, m);
  }

  @override
  Stream<List<Tournament>> watchByClub(String clubId) => _col
      .where('clubId', isEqualTo: clubId)
      .snapshots()
      .map((s) => s.docs.map(_t).toList()
        ..sort((a, b) => (a.startAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(b.startAt?.millisecondsSinceEpoch ?? 0)));

  @override
  Future<void> create(Tournament t) => _col.add(t.toMap());

  @override
  Future<void> update(Tournament t) => _col.doc(t.id).set(t.toMap());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
