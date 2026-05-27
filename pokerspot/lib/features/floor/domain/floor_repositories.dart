// Floor domain repository interfaces (spec §12). Pure Dart — no Firebase.
// Concrete Fake / Firebase implementations live in features/floor/data.

import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

abstract interface class TablesRepository {
  /// Live tables for a club (clubs/{clubId}/tables), ordered by number.
  Stream<List<PokerTable>> watchTables(String clubId);

  /// Create a table; returns the new doc id.
  Future<String> createTable({
    required String clubId,
    required int number,
    required Stakes stakes,
    required int seatCount,
    required bool open,
    num? avgStack,
    num? minBuyIn,
  });

  /// Update an existing table's fields (matched by [table.clubId]/[table.id]).
  Future<void> updateTable(PokerTable table);

  /// Delete a table.
  Future<void> deleteTable({required String clubId, required String tableId});
}

abstract interface class WaitlistRepository {
  /// Live active (waiting|called) entries for a club, oldest first.
  Stream<List<WaitlistEntry>> watchByClub(String clubId);

  /// Live active entries for one player (across clubs).
  Stream<List<WaitlistEntry>> watchByPlayer(String playerUid);

  /// Player joins a specific table's waitlist.
  Future<void> join({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  });

  /// Player cancels their entry (status -> cancelled).
  Future<void> cancel(String entryId);

  /// Pit Boss calls a waiting entry (status -> called, stamps calledAt).
  Future<void> call(String entryId);

  /// Mark an entry seated (status -> seated) without creating a session — used
  /// when the player is seated from an already-held seat.
  Future<void> markSeated(String entryId);

  /// Pit Boss seats a called/waiting entry: creates an active Session at
  /// [tableId]/[seatNumber] and flips the entry to seated (atomic on Firebase).
  Future<void> seat({
    required WaitlistEntry entry,
    required String tableId,
    required int seatNumber,
  });
}

abstract interface class SessionsRepository {
  /// Live open sessions for a club — active AND held (both occupy a seat).
  Stream<List<Session>> watchActiveByClub(String clubId);

  /// Live ALL sessions for a club (active + ended) — Super Admin analytics.
  Stream<List<Session>> watchAllByClub(String clubId);

  /// Live open sessions for one player — active AND held (reserved/called seat).
  Stream<List<Session>> watchByPlayer(String playerUid);

  /// ALL sessions for one player (active + ended) — playtime stats.
  Stream<List<Session>> watchAllByPlayer(String playerUid);

  /// Seat a walk-in (no waitlist / no auth): creates an active Session with a
  /// synthetic `walk-in:<rand>` playerUid.
  Future<void> seatWalkIn({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerName,
  });

  /// Seat a registered player directly (not via the waitlist) — keeps their real
  /// [playerUid] so the session shows in their own activity.
  Future<void> seatPlayer({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerUid,
    required String playerName,
  });

  /// Hold a seat for a player (status held) — a 30-min reservation or a 10-min
  /// waitlist call. Auto-released by expireHolds when [heldUntil] passes.
  Future<void> holdSeat({
    required String clubId,
    required String tableId,
    required int seatNumber,
    required Stakes stakes,
    required String playerUid,
    required String playerName,
    required String holdKind,
    required int durationMinutes,
  });

  /// Convert a held seat to an active session (the player arrived & was seated).
  Future<void> seatFromHold(String sessionId);

  /// Release a held seat (status -> ended) without seating.
  Future<void> releaseHold(String sessionId);

  /// End a session (status -> ended, stamps endedAt).
  Future<void> end(String sessionId);
}

abstract interface class ReservationsRepository {
  /// A player's active (held) reservations.
  Stream<List<Reservation>> watchByPlayer(String playerUid);

  /// A club's active (held) reservations (Pit Boss view).
  Stream<List<Reservation>> watchByClub(String clubId);

  /// Player reserves a seat — instant hold for [durationMinutes] (per-club, 30 default).
  Future<void> reserve({
    required String clubId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
    required int durationMinutes,
  });

  /// Player cancels (status -> cancelled).
  Future<void> cancel(String reservationId);

  /// Pit Boss marks the player arrived (status -> arrived).
  Future<void> markArrived(String reservationId);
}
