import 'package:pokerspot/features/tournaments/domain/tournament.dart';

abstract interface class TournamentsRepository {
  /// Live upcoming tournaments for a club (soonest first).
  Stream<List<Tournament>> watchByClub(String clubId);

  /// Pit Boss / Admin creates a tournament.
  Future<void> create(Tournament t);

  /// Pit Boss / Admin cancels a tournament.
  Future<void> delete(String id);
}
