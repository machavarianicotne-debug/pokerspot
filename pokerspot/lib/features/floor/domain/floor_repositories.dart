// Floor domain repository interfaces (spec §12). Pure Dart — no Firebase.
// Concrete Fake / Firebase implementations live in features/floor/data.

import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

abstract interface class TablesRepository {
  /// Live tables for a club (clubs/{clubId}/tables), ordered by number.
  Stream<List<PokerTable>> watchTables(String clubId);
}

abstract interface class WaitlistRepository {
  /// Live active (waiting|called) entries for a club, oldest first.
  Stream<List<WaitlistEntry>> watchByClub(String clubId);

  /// Live active entries for one player (across clubs).
  Stream<List<WaitlistEntry>> watchByPlayer(String playerUid);

  /// Player joins a club's waitlist for a stake.
  Future<void> join({
    required String clubId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  });

  /// Player cancels their entry (status -> cancelled).
  Future<void> cancel(String entryId);

  /// Pit Boss calls a waiting entry (status -> called, stamps calledAt).
  Future<void> call(String entryId);

  /// Pit Boss seats a called/waiting entry: creates an active Session at
  /// [tableId]/[seatNumber] and flips the entry to seated (atomic on Firebase).
  Future<void> seat({
    required WaitlistEntry entry,
    required String tableId,
    required int seatNumber,
  });
}

abstract interface class SessionsRepository {
  /// Live active sessions for a club.
  Stream<List<Session>> watchActiveByClub(String clubId);

  /// Live active sessions for one player.
  Stream<List<Session>> watchByPlayer(String playerUid);

  /// End a session (status -> ended, stamps endedAt).
  Future<void> end(String sessionId);
}
