import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/tournaments/data/firebase_tournament_registrations_repository.dart';
import 'package:pokerspot/features/tournaments/data/firebase_tournaments_repository.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registrations_repository.dart';
import 'package:pokerspot/features/tournaments/domain/tournaments_repository.dart';

final tournamentsRepositoryProvider = Provider<TournamentsRepository>(
    (ref) => FirebaseTournamentsRepository(FirebaseFirestore.instance));

final tournamentRegistrationsRepositoryProvider = Provider<TournamentRegistrationsRepository>(
    (ref) => FirebaseTournamentRegistrationsRepository(FirebaseFirestore.instance));

/// Upcoming tournaments for a club (gated on auth — reads require signedIn()).
final clubTournamentsProvider = StreamProvider.family<List<Tournament>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Tournament>[]);
  return ref.watch(tournamentsRepositoryProvider).watchByClub(clubId);
});

/// Live sign-ups for one tournament (gated on auth). Ordered oldest-first; the
/// first `maxPlayers` are registered, the rest are the waitlist.
final tournamentRegistrationsProvider =
    StreamProvider.family<List<TournamentRegistration>, String>((ref, tournamentId) {
  if (ref.watch(uidProvider).valueOrNull == null) {
    return Stream.value(const <TournamentRegistration>[]);
  }
  return ref.watch(tournamentRegistrationsRepositoryProvider).watchByTournament(tournamentId);
});
