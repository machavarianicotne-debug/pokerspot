// Clubs domain model (spec §12). Pure Dart — no Firebase imports.
// [id] is the Firestore document id; it is not part of toMap().

/// A per-stake live summary for a club (denormalized onto the club doc by the
/// syncClubStats Cloud Function, so players — who can't read other clubs'
/// sessions/waitlist — still see the scoreboard on the club-details screen).
class ClubGame {
  final String label; // e.g. "NLH 1/2 GEL"
  final String type; // variant short label, e.g. "NLH"
  final num? minBuyIn;
  final num? avgStack;
  final int tables;
  final int openSeats;
  final int waiting;

  const ClubGame({
    required this.label,
    required this.type,
    required this.minBuyIn,
    required this.avgStack,
    required this.tables,
    required this.openSeats,
    required this.waiting,
  });

  factory ClubGame.fromMap(Map<String, dynamic> m) => ClubGame(
        label: (m['label'] ?? '') as String,
        type: (m['type'] ?? '') as String,
        minBuyIn: m['minBuyIn'] as num?,
        avgStack: m['avgStack'] as num?,
        tables: (m['tables'] ?? 0) as int,
        openSeats: (m['openSeats'] ?? 0) as int,
        waiting: (m['waiting'] ?? 0) as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClubGame &&
          label == other.label &&
          type == other.type &&
          minBuyIn == other.minBuyIn &&
          avgStack == other.avgStack &&
          tables == other.tables &&
          openSeats == other.openSeats &&
          waiting == other.waiting;

  @override
  int get hashCode => Object.hash(label, type, minBuyIn, avgStack, tables, openSeats, waiting);
}

class Club {
  final String id;
  final String name;
  final String city;
  final String address;
  final String? photoUrl;
  final String hoursText;
  final String phone;
  final bool enabled;
  final String currency; // default stake currency (GEL/USD/EUR)
  final List<String> languages; // supported languages (ka/en/ru)

  // ---- Denormalized live aggregates (written by the syncClubStats Cloud
  // Function). Players may read a club doc but not other clubs' sessions /
  // waitlist, so these summary numbers live on the club itself.
  final bool live; // at least one game has players seated
  final int openSeats; // free seats across open tables
  final int players; // seated players across the club
  final int stakes; // distinct stakes currently running
  final int waiting; // active waitlist entries
  final List<ClubGame> games; // per-stake live scoreboard (function-populated)

  const Club({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.photoUrl,
    required this.hoursText,
    required this.phone,
    required this.enabled,
    this.currency = 'GEL',
    this.languages = const [],
    this.live = false,
    this.openSeats = 0,
    this.players = 0,
    this.stakes = 0,
    this.waiting = 0,
    this.games = const [],
  });

  factory Club.fromMap(String id, Map<String, dynamic> m) => Club(
        id: id,
        name: (m['name'] ?? '') as String,
        city: (m['city'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        photoUrl: m['photoUrl'] as String?,
        hoursText: (m['hoursText'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        enabled: (m['enabled'] ?? false) as bool,
        currency: (m['currency'] ?? 'GEL') as String,
        languages: (m['languages'] as List?)?.whereType<String>().toList() ?? const [],
        live: (m['live'] ?? false) as bool,
        openSeats: (m['openSeats'] ?? 0) as int,
        players: (m['players'] ?? 0) as int,
        stakes: (m['stakes'] ?? 0) as int,
        waiting: (m['waiting'] ?? 0) as int,
        games: (m['games'] as List?)
                ?.whereType<Map>()
                .map((e) => ClubGame.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'address': address,
        'photoUrl': photoUrl,
        'hoursText': hoursText,
        'phone': phone,
        'enabled': enabled,
        'currency': currency,
        'languages': languages,
      };

  Club copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? photoUrl,
    String? hoursText,
    String? phone,
    bool? enabled,
    String? currency,
    List<String>? languages,
    bool? live,
    int? openSeats,
    int? players,
    int? stakes,
    int? waiting,
    List<ClubGame>? games,
  }) =>
      Club(
        id: id ?? this.id,
        name: name ?? this.name,
        city: city ?? this.city,
        address: address ?? this.address,
        photoUrl: photoUrl ?? this.photoUrl,
        hoursText: hoursText ?? this.hoursText,
        phone: phone ?? this.phone,
        enabled: enabled ?? this.enabled,
        currency: currency ?? this.currency,
        languages: languages ?? this.languages,
        live: live ?? this.live,
        openSeats: openSeats ?? this.openSeats,
        players: players ?? this.players,
        stakes: stakes ?? this.stakes,
        waiting: waiting ?? this.waiting,
        games: games ?? this.games,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Club &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          city == other.city &&
          address == other.address &&
          photoUrl == other.photoUrl &&
          hoursText == other.hoursText &&
          phone == other.phone &&
          enabled == other.enabled &&
          currency == other.currency &&
          _listEq(languages, other.languages) &&
          live == other.live &&
          openSeats == other.openSeats &&
          players == other.players &&
          stakes == other.stakes &&
          waiting == other.waiting &&
          _listEq(games, other.games);

  @override
  int get hashCode => Object.hash(id, name, city, address, photoUrl, hoursText, phone, enabled,
      currency, Object.hashAll(languages), live, openSeats, players, stakes, waiting,
      Object.hashAll(games));

  static bool _listEq(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
