import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';

abstract interface class TournamentRegistrationsRepository {
  /// Live sign-ups for one tournament, oldest first (sign-up = seat priority).
  Stream<List<TournamentRegistration>> watchByTournament(String tournamentId);

  /// Player signs up for themselves.
  Future<void> register(TournamentRegistration r);

  /// Player (or staff) removes a player's sign-up for a tournament.
  Future<void> unregister(String tournamentId, String playerUid);
}
