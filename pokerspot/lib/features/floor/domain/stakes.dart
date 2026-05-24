// Floor domain — stakes (spec §12). Pure Dart — no Firebase imports.

import 'package:pokerspot/core/constants/business_rules.dart';

enum GameVariant {
  nlh,
  plo,
  plo5,
  plo6;

  static GameVariant fromString(String? raw) {
    switch (raw) {
      case 'plo':
        return GameVariant.plo;
      case 'plo5':
        return GameVariant.plo5;
      case 'plo6':
        return GameVariant.plo6;
      default:
        return GameVariant.nlh;
    }
  }

  String get asString => name;

  String get label {
    switch (this) {
      case GameVariant.nlh:
        return 'NLH';
      case GameVariant.plo:
        return 'PLO';
      case GameVariant.plo5:
        return 'PLO5';
      case GameVariant.plo6:
        return 'PLO6';
    }
  }
}

/// A stake = game variant + blinds + currency. Serializes to flat keys
/// (`variant`, `smallBlind`, `bigBlind`, `currency`) so it can be embedded in
/// table / waitlist / session docs.
class Stakes {
  final GameVariant variant;
  final num smallBlind;
  final num bigBlind;
  final String currency;

  const Stakes({
    required this.variant,
    required this.smallBlind,
    required this.bigBlind,
    required this.currency,
  });

  /// e.g. "NLH 1/2 GEL".
  String get label => '${variant.label} ${_fmt(smallBlind)}/${_fmt(bigBlind)} $currency';

  static String _fmt(num n) => n == n.truncate() ? n.toInt().toString() : n.toString();

  factory Stakes.fromMap(Map<String, dynamic> m) => Stakes(
        variant: GameVariant.fromString(m['variant'] as String?),
        smallBlind: (m['smallBlind'] ?? 0) as num,
        bigBlind: (m['bigBlind'] ?? 0) as num,
        currency: (m['currency'] ?? BusinessRules.defaultCurrency) as String,
      );

  Map<String, dynamic> toMap() => {
        'variant': variant.asString,
        'smallBlind': smallBlind,
        'bigBlind': bigBlind,
        'currency': currency,
      };

  Stakes copyWith({
    GameVariant? variant,
    num? smallBlind,
    num? bigBlind,
    String? currency,
  }) =>
      Stakes(
        variant: variant ?? this.variant,
        smallBlind: smallBlind ?? this.smallBlind,
        bigBlind: bigBlind ?? this.bigBlind,
        currency: currency ?? this.currency,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stakes &&
          runtimeType == other.runtimeType &&
          variant == other.variant &&
          smallBlind == other.smallBlind &&
          bigBlind == other.bigBlind &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(variant, smallBlind, bigBlind, currency);
}
