import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/domain/clubs_repository.dart';

/// Firestore-backed [ClubsRepository]. Clubs live in the `clubs` collection,
/// one doc per club; players read enabled clubs only. Not unit-tested (live
/// Firestore); verified via `flutter analyze` + the live app.
class FirebaseClubsRepository implements ClubsRepository {
  FirebaseClubsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('clubs');

  @override
  Stream<List<Club>> watchEnabledClubs() => _col
      .where('enabled', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Club.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<Club>> watchAllClubs() => _col.snapshots().map((s) =>
      s.docs.map((d) => Club.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<String> createClub(Club draft) async {
    final doc = await _col.add(draft.toMap());
    return doc.id;
  }

  @override
  Future<void> updateClub(Club club) => _col.doc(club.id).set(club.toMap());

  @override
  Future<void> setClubEnabled(String id, bool enabled) =>
      _col.doc(id).update({'enabled': enabled});

  @override
  Future<void> setReservationMinutes(String id, int minutes) =>
      _col.doc(id).update({'reservationMinutes': minutes});

  @override
  Stream<Club?> watchClub(String id) => _col.doc(id).snapshots().map(
        (d) => d.exists ? Club.fromMap(d.id, d.data()!) : null,
      );

  @override
  Future<Club?> getClub(String id) async {
    final d = await _col.doc(id).get();
    return d.exists ? Club.fromMap(d.id, d.data()!) : null;
  }
}
