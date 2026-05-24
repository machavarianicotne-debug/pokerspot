import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/clubs/data/firebase_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/domain/clubs_repository.dart';

final clubsRepositoryProvider = Provider<ClubsRepository>(
    (ref) => FirebaseClubsRepository(FirebaseFirestore.instance));

/// Live list of enabled clubs.
final clubsListProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(clubsRepositoryProvider).watchEnabledClubs();
});

/// Live single club by id.
final clubProvider = StreamProvider.family<Club?, String>((ref, id) {
  return ref.watch(clubsRepositoryProvider).watchClub(id);
});
