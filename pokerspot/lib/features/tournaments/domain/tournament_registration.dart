// One player's sign-up for a tournament. Pure Dart, no Firebase.
// Flat collection tournament_registrations/{id}; createdAt stored as epoch
// millis. There is NO stored status: the registrations are ordered by
// createdAt and the first `maxPlayers` are "registered", the rest "waitlisted".
// When someone cancels, the ordering shifts and the next person moves up — no
// promotion bookkeeping (or Cloud Function) needed.

class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String clubId;
  final String playerUid;
  final String playerName;
  final int createdAt; // epoch millis — sign-up order (and thus seat priority)

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.createdAt,
  });

  factory TournamentRegistration.fromMap(String id, Map<String, dynamic> m) =>
      TournamentRegistration(
        id: id,
        tournamentId: (m['tournamentId'] ?? '') as String,
        clubId: (m['clubId'] ?? '') as String,
        playerUid: (m['playerUid'] ?? '') as String,
        playerName: (m['playerName'] ?? '') as String,
        createdAt: (m['createdAt'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'tournamentId': tournamentId,
        'clubId': clubId,
        'playerUid': playerUid,
        'playerName': playerName,
        'createdAt': createdAt,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentRegistration &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tournamentId == other.tournamentId &&
          clubId == other.clubId &&
          playerUid == other.playerUid &&
          playerName == other.playerName &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, tournamentId, clubId, playerUid, playerName, createdAt);
}
