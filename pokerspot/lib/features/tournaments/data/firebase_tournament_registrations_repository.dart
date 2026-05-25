import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registrations_repository.dart';

/// Firestore-backed tournament sign-ups. Flat `tournament_registrations`
/// collection; filter by tournamentId (single-field index) and sort by
/// createdAt client-side so no composite index is needed.
class FirebaseTournamentRegistrationsRepository
    implements TournamentRegistrationsRepository {
  FirebaseTournamentRegistrationsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tournament_registrations');

  TournamentRegistration _r(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    final at = m['createdAt'];
    m['createdAt'] = at is Timestamp ? at.millisecondsSinceEpoch : at;
    return TournamentRegistration.fromMap(d.id, m);
  }

  @override
  Stream<List<TournamentRegistration>> watchByTournament(String tournamentId) => _col
      .where('tournamentId', isEqualTo: tournamentId)
      .snapshots()
      .map((s) => s.docs.map(_r).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  @override
  Future<void> register(TournamentRegistration r) => _col.add(r.toMap());

  @override
  Future<void> unregister(String tournamentId, String playerUid) async {
    final q = await _col
        .where('tournamentId', isEqualTo: tournamentId)
        .where('playerUid', isEqualTo: playerUid)
        .get();
    for (final d in q.docs) {
      await d.reference.delete();
    }
  }
}
