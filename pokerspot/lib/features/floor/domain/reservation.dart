// Floor domain — a seat reservation (instant 30-min hold). Pure Dart, no
// Firebase imports. Top-level collection reservations/{id}; timestamps stored as
// epoch millis (the Firebase repo converts Firestore Timestamps <-> millis).

import 'package:pokerspot/features/floor/domain/stakes.dart';

enum ReservationStatus {
  held,
  arrived,
  expired,
  cancelled;

  static ReservationStatus fromString(String? raw) {
    switch (raw) {
      case 'arrived':
        return ReservationStatus.arrived;
      case 'expired':
        return ReservationStatus.expired;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.held;
    }
  }

  String get asString => name;
}

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class Reservation {
  final String id;
  final String clubId;
  final String? tableId;
  final String playerUid;
  final String playerName;
  final Stakes stakes;
  final ReservationStatus status;
  final DateTime? heldUntil;
  final DateTime? createdAt;

  const Reservation({
    required this.id,
    required this.clubId,
    this.tableId,
    required this.playerUid,
    required this.playerName,
    required this.stakes,
    required this.status,
    required this.heldUntil,
    required this.createdAt,
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> m) => Reservation(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        tableId: m['tableId'] as String?,
        playerUid: (m['playerUid'] ?? '') as String,
        playerName: (m['playerName'] ?? '') as String,
        stakes: Stakes.fromMap(m),
        status: ReservationStatus.fromString(m['status'] as String?),
        heldUntil: _date(m['heldUntil']),
        createdAt: _date(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'tableId': tableId,
        'playerUid': playerUid,
        'playerName': playerName,
        ...stakes.toMap(),
        'status': status.asString,
        'heldUntil': heldUntil?.millisecondsSinceEpoch,
        'createdAt': createdAt?.millisecondsSinceEpoch,
      };

  Reservation copyWith({ReservationStatus? status, DateTime? heldUntil}) => Reservation(
        id: id,
        clubId: clubId,
        tableId: tableId,
        playerUid: playerUid,
        playerName: playerName,
        stakes: stakes,
        status: status ?? this.status,
        heldUntil: heldUntil ?? this.heldUntil,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reservation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          tableId == other.tableId &&
          playerUid == other.playerUid &&
          playerName == other.playerName &&
          stakes == other.stakes &&
          status == other.status &&
          heldUntil == other.heldUntil &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, clubId, tableId, playerUid, playerName, stakes, status, heldUntil, createdAt);
}
