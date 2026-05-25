// Tournaments domain — a club's announced tournament. Pure Dart, no Firebase.
// Top-level collection tournaments/{id}; startAt stored as epoch millis.

enum TournamentType {
  freezeout,
  knockoutRebuy, // knockout + rebuy
  rebuy,
  rebuyAddon; // rebuy + add-on

  static TournamentType fromString(String? raw) {
    switch (raw) {
      case 'knockoutRebuy':
        return TournamentType.knockoutRebuy;
      case 'rebuy':
        return TournamentType.rebuy;
      case 'rebuyAddon':
        return TournamentType.rebuyAddon;
      default:
        return TournamentType.freezeout;
    }
  }

  String get asString => name;

  /// Whether this type involves re-buys (shows the re-buy fee).
  bool get hasRebuy =>
      this == knockoutRebuy || this == rebuy || this == rebuyAddon;
}

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class Tournament {
  final String id;
  final String clubId;
  final String name;
  final TournamentType type;
  final DateTime? startAt;
  final num buyIn;
  final num? rebuyFee; // when the type has re-buys
  final bool hasAddon;
  final num? addonFee; // when hasAddon
  final int blindMinutes;
  final String currency;

  const Tournament({
    required this.id,
    required this.clubId,
    required this.name,
    required this.type,
    required this.startAt,
    required this.buyIn,
    required this.rebuyFee,
    required this.hasAddon,
    required this.addonFee,
    required this.blindMinutes,
    required this.currency,
  });

  factory Tournament.fromMap(String id, Map<String, dynamic> m) => Tournament(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        type: TournamentType.fromString(m['type'] as String?),
        startAt: _date(m['startAt']),
        buyIn: (m['buyIn'] ?? 0) as num,
        rebuyFee: m['rebuyFee'] as num?,
        hasAddon: (m['hasAddon'] ?? false) as bool,
        addonFee: m['addonFee'] as num?,
        blindMinutes: (m['blindMinutes'] ?? 20) as int,
        currency: (m['currency'] ?? 'GEL') as String,
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'name': name,
        'type': type.asString,
        'startAt': startAt?.millisecondsSinceEpoch,
        'buyIn': buyIn,
        'rebuyFee': rebuyFee,
        'hasAddon': hasAddon,
        'addonFee': addonFee,
        'blindMinutes': blindMinutes,
        'currency': currency,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          name == other.name &&
          type == other.type &&
          startAt == other.startAt &&
          buyIn == other.buyIn &&
          rebuyFee == other.rebuyFee &&
          hasAddon == other.hasAddon &&
          addonFee == other.addonFee &&
          blindMinutes == other.blindMinutes &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(id, clubId, name, type, startAt, buyIn, rebuyFee, hasAddon,
      addonFee, blindMinutes, currency);
}
