// Floor domain — a table at a club (spec §12). Pure Dart — no Firebase imports.
// Lives at clubs/{clubId}/tables/{id}; [id] is the doc id, [clubId] the parent.

import 'package:pokerspot/core/constants/business_rules.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';

class PokerTable {
  final String id;
  final String clubId;
  final int number;
  final Stakes stakes;
  final int seatCount;
  final bool open;

  const PokerTable({
    required this.id,
    required this.clubId,
    required this.number,
    required this.stakes,
    required this.seatCount,
    required this.open,
  });

  factory PokerTable.fromMap(String id, String clubId, Map<String, dynamic> m) => PokerTable(
        id: id,
        clubId: clubId,
        number: (m['number'] ?? 0) as int,
        stakes: Stakes.fromMap(m),
        seatCount: (m['seatCount'] ?? BusinessRules.maxPlayersPerTable) as int,
        open: (m['open'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'number': number,
        ...stakes.toMap(),
        'seatCount': seatCount,
        'open': open,
      };

  PokerTable copyWith({
    String? id,
    String? clubId,
    int? number,
    Stakes? stakes,
    int? seatCount,
    bool? open,
  }) =>
      PokerTable(
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        number: number ?? this.number,
        stakes: stakes ?? this.stakes,
        seatCount: seatCount ?? this.seatCount,
        open: open ?? this.open,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokerTable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          number == other.number &&
          stakes == other.stakes &&
          seatCount == other.seatCount &&
          open == other.open;

  @override
  int get hashCode => Object.hash(id, clubId, number, stakes, seatCount, open);
}
