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

  /// NLH/PLO mixed-game config (only meaningful when stakes.variant == nlhPlo;
  /// ignored otherwise). [omahaPerCircle] = Omaha hands per orbit (1 or 2);
  /// [omahaVariant] = which Omaha is dealt (plo or plo5). Null until set.
  final int? omahaPerCircle;
  final GameVariant? omahaVariant;

  const PokerTable({
    required this.id,
    required this.clubId,
    required this.number,
    required this.stakes,
    required this.seatCount,
    required this.open,
    this.avgStack,
    this.minBuyIn,
    this.omahaPerCircle,
    this.omahaVariant,
  });

  /// Display suffix for an NLH game with Omaha mixed in, e.g. "x2PLO5" (count +
  /// Omaha variant). Empty for plain NLH or non-NLH games.
  String get omahaSuffix => (stakes.variant == GameVariant.nlh && omahaPerCircle != null)
      ? 'x$omahaPerCircle${(omahaVariant ?? GameVariant.plo).label}'
      : '';

  factory PokerTable.fromMap(String id, String clubId, Map<String, dynamic> m) => PokerTable(
        id: id,
        clubId: clubId,
        number: (m['number'] ?? 0) as int,
        stakes: Stakes.fromMap(m),
        seatCount: (m['seatCount'] ?? BusinessRules.maxPlayersPerTable) as int,
        open: (m['open'] ?? false) as bool,
        avgStack: m['avgStack'] as num?,
        minBuyIn: m['minBuyIn'] as num?,
        omahaPerCircle: m['omahaPerCircle'] as int?,
        omahaVariant:
            m['omahaVariant'] == null ? null : GameVariant.fromString(m['omahaVariant'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'number': number,
        ...stakes.toMap(),
        'seatCount': seatCount,
        'open': open,
        'avgStack': avgStack,
        'minBuyIn': minBuyIn,
        'omahaPerCircle': omahaPerCircle,
        'omahaVariant': omahaVariant?.asString,
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
    int? omahaPerCircle,
    GameVariant? omahaVariant,
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
        omahaPerCircle: omahaPerCircle ?? this.omahaPerCircle,
        omahaVariant: omahaVariant ?? this.omahaVariant,
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
          minBuyIn == other.minBuyIn &&
          omahaPerCircle == other.omahaPerCircle &&
          omahaVariant == other.omahaVariant;

  @override
  int get hashCode => Object.hash(
      id, clubId, number, stakes, seatCount, open, avgStack, minBuyIn, omahaPerCircle, omahaVariant);
}
