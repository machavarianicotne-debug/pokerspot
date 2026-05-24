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

  /// Optional Pit-Boss-editable economics (display only; mirror across same-stake
  /// tables). Null until set.
  final num? avgStack;
  final num? minBuyIn;

  const PokerTable({
    required this.id,
    required this.clubId,
    required this.number,
    required this.stakes,
    required this.seatCount,
    required this.open,
    this.avgStack,
    this.minBuyIn,
  });

  factory PokerTable.fromMap(String id, String clubId, Map<String, dynamic> m) => PokerTable(
        id: id,
        clubId: clubId,
        number: (m['number'] ?? 0) as int,
        stakes: Stakes.fromMap(m),
        seatCount: (m['seatCount'] ?? BusinessRules.maxPlayersPerTable) as int,
        open: (m['open'] ?? false) as bool,
        avgStack: m['avgStack'] as num?,
        minBuyIn: m['minBuyIn'] as num?,
      );

  Map<String, dynamic> toMap() => {
        'number': number,
        ...stakes.toMap(),
        'seatCount': seatCount,
        'open': open,
        'avgStack': avgStack,
        'minBuyIn': minBuyIn,
      };

  PokerTable copyWith({
    String? id,
    String? clubId,
    int? number,
    Stakes? stakes,
    int? seatCount,
    bool? open,
    num? avgStack,
    num? minBuyIn,
  }) =>
      PokerTable(
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        number: number ?? this.number,
        stakes: stakes ?? this.stakes,
        seatCount: seatCount ?? this.seatCount,
        open: open ?? this.open,
        avgStack: avgStack ?? this.avgStack,
        minBuyIn: minBuyIn ?? this.minBuyIn,
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
          open == other.open &&
          avgStack == other.avgStack &&
          minBuyIn == other.minBuyIn;

  @override
  int get hashCode =>
      Object.hash(id, clubId, number, stakes, seatCount, open, avgStack, minBuyIn);
}
