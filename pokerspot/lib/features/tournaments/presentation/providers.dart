import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/tournaments/data/firebase_tournaments_repository.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournaments_repository.dart';

final tournamentsRepositoryProvider = Provider<TournamentsRepository>(
    (ref) => FirebaseTournamentsRepository(FirebaseFirestore.instance));

/// Upcoming tournaments for a club (gated on auth — reads require signedIn()).
final clubTournamentsProvider = StreamProvider.family<List<Tournament>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Tournament>[]);
  return ref.watch(tournamentsRepositoryProvider).watchByClub(clubId);
});
