// Clubs domain interface (spec §12). Pure Dart — no Firebase imports.
// Concrete Fake / Firebase implementations live in features/clubs/data.

import 'package:pokerspot/features/clubs/domain/club.dart';

abstract interface class ClubsRepository {
  /// Live list of enabled clubs (players only see enabled ones).
  Stream<List<Club>> watchEnabledClubs();

  /// Live list of ALL clubs (Super Admin — includes disabled).
  Stream<List<Club>> watchAllClubs();

  /// Live single club by id (null until it exists / if removed).
  Stream<Club?> watchClub(String id);

  /// One-shot read of a single club.
  Future<Club?> getClub(String id);

  /// Create a club (the [draft]'s id is ignored); returns the new doc id.
  Future<String> createClub(Club draft);

  /// Update a club's fields (matched by [club.id]).
  Future<void> updateClub(Club club);

  /// Enable / disable a club (controls player visibility).
  Future<void> setClubEnabled(String id, bool enabled);
}
