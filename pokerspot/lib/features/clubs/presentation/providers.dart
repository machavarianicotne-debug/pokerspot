import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/data/firebase_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/domain/clubs_repository.dart';

final clubsRepositoryProvider = Provider<ClubsRepository>(
    (ref) => FirebaseClubsRepository(FirebaseFirestore.instance));

// All club reads require signedIn() under the rules — gate on auth so a query
// never fires before the session is ready (the cause of intermittent
// permission-denied on the home screen right after sign-in / on reload).

/// Live list of enabled clubs.
final clubsListProvider = StreamProvider<List<Club>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <Club>[]);
  return ref.watch(clubsRepositoryProvider).watchEnabledClubs();
});

/// Live single club by id.
final clubProvider = StreamProvider.family<Club?, String>((ref, id) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream<Club?>.value(null);
  return ref.watch(clubsRepositoryProvider).watchClub(id);
});

/// Live list of ALL clubs (Super Admin — includes disabled).
final allClubsProvider = StreamProvider<List<Club>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <Club>[]);
  return ref.watch(clubsRepositoryProvider).watchAllClubs();
});
