// Floor domain — a seated session (spec §12). Pure Dart, no Firebase imports.
// Top-level collection sessions/{id}. Timestamps stored as epoch millis (int);
// the Firebase repository converts Firestore Timestamps <-> millis.

import 'package:pokerspot/features/floor/domain/stakes.dart';

enum SessionStatus {
  active,
  ended;

  static SessionStatus fromString(String? raw) =>
      raw == 'ended' ? SessionStatus.ended : SessionStatus.active;

  String get asString => name;
}

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class Session {
  final String id;
  final String clubId;
  final String tableId;
  final int seatNumber;
  final String playerUid;
  final String playerName;
  final Stakes stakes;
  final SessionStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const Session({
    required this.id,
    required this.clubId,
    required this.tableId,
    required this.seatNumber,
    required this.playerUid,
    required this.playerName,
    required this.stakes,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  /// Elapsed time as of [now] (or until [endedAt] if ended). Null if not started.
  Duration? elapsedAt(DateTime now) {
    final start = startedAt;
    if (start == null) return null;
    final end = endedAt ?? now;
    return end.difference(start);
  }

  factory Session.fromMap(String id, Map<String, dynamic> m) => Session(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        tableId: (m['tableId'] ?? '') as String,
        seatNumber: (m['seatNumber'] ?? 0) as int,
        playerUid: (m['playerUid'] ?? '') as String,
        playerName: (m['playerName'] ?? '') as String,
        stakes: Stakes.fromMap(m),
        status: SessionStatus.fromString(m['status'] as String?),
        startedAt: _date(m['startedAt']),
        endedAt: _date(m['endedAt']),
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'tableId': tableId,
        'seatNumber': seatNumber,
        'playerUid': playerUid,
        'playerName': playerName,
        ...stakes.toMap(),
        'status': status.asString,
        'startedAt': startedAt?.millisecondsSinceEpoch,
        'endedAt': endedAt?.millisecondsSinceEpoch,
      };

  Session copyWith({
    String? id,
    String? clubId,
    String? tableId,
    int? seatNumber,
    String? playerUid,
    String? playerName,
    Stakes? stakes,
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
  }) =>
      Session(
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        tableId: tableId ?? this.tableId,
        seatNumber: seatNumber ?? this.seatNumber,
        playerUid: playerUid ?? this.playerUid,
        playerName: playerName ?? this.playerName,
        stakes: stakes ?? this.stakes,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          tableId == other.tableId &&
          seatNumber == other.seatNumber &&
          playerUid == other.playerUid &&
          playerName == other.playerName &&
          stakes == other.stakes &&
          status == other.status &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt;

  @override
  int get hashCode => Object.hash(id, clubId, tableId, seatNumber, playerUid,
      playerName, stakes, status, startedAt, endedAt);
}
