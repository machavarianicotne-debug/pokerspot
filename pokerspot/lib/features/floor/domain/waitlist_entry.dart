// Floor domain — a per-stake waitlist entry (spec §12). Pure Dart, no Firebase.
// Top-level collection waitlist/{id}. Timestamps are stored as epoch millis
// (int); the Firebase repository converts Firestore Timestamps <-> millis so
// this layer stays Firebase-free.

import 'package:pokerspot/features/floor/domain/stakes.dart';

enum WaitlistStatus {
  waiting,
  called,
  seated,
  cancelled;

  static WaitlistStatus fromString(String? raw) {
    switch (raw) {
      case 'called':
        return WaitlistStatus.called;
      case 'seated':
        return WaitlistStatus.seated;
      case 'cancelled':
        return WaitlistStatus.cancelled;
      default:
        return WaitlistStatus.waiting;
    }
  }

  String get asString => name;
}

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class WaitlistEntry {
  final String id;
  final String clubId;
  final String playerUid;
  final String playerName;
  final Stakes stakes;
  final WaitlistStatus status;
  final DateTime? createdAt;
  final DateTime? calledAt;

  const WaitlistEntry({
    required this.id,
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.stakes,
    required this.status,
    required this.createdAt,
    required this.calledAt,
  });

  factory WaitlistEntry.fromMap(String id, Map<String, dynamic> m) => WaitlistEntry(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        playerUid: (m['playerUid'] ?? '') as String,
        playerName: (m['playerName'] ?? '') as String,
        stakes: Stakes.fromMap(m),
        status: WaitlistStatus.fromString(m['status'] as String?),
        createdAt: _date(m['createdAt']),
        calledAt: _date(m['calledAt']),
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'playerUid': playerUid,
        'playerName': playerName,
        ...stakes.toMap(),
        'status': status.asString,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'calledAt': calledAt?.millisecondsSinceEpoch,
      };

  WaitlistEntry copyWith({
    String? id,
    String? clubId,
    String? playerUid,
    String? playerName,
    Stakes? stakes,
    WaitlistStatus? status,
    DateTime? createdAt,
    DateTime? calledAt,
  }) =>
      WaitlistEntry(
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        playerUid: playerUid ?? this.playerUid,
        playerName: playerName ?? this.playerName,
        stakes: stakes ?? this.stakes,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        calledAt: calledAt ?? this.calledAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaitlistEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          playerUid == other.playerUid &&
          playerName == other.playerName &&
          stakes == other.stakes &&
          status == other.status &&
          createdAt == other.createdAt &&
          calledAt == other.calledAt;

  @override
  int get hashCode => Object.hash(
      id, clubId, playerUid, playerName, stakes, status, createdAt, calledAt);
}
