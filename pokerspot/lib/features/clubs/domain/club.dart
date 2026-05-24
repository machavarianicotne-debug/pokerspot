// Clubs domain model (spec §12). Pure Dart — no Firebase imports.
// [id] is the Firestore document id; it is not part of toMap().

class Club {
  final String id;
  final String name;
  final String city;
  final String address;
  final String? photoUrl;
  final String hoursText;
  final String phone;
  final bool enabled;

  // ---- Denormalized live aggregates (written by the syncClubStats Cloud
  // Function). Players may read a club doc but not other clubs' sessions /
  // waitlist, so these summary numbers live on the club itself.
  final bool live; // at least one game has players seated
  final int openSeats; // free seats across open tables
  final int stakes; // distinct stakes currently running
  final int waiting; // active waitlist entries

  const Club({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.photoUrl,
    required this.hoursText,
    required this.phone,
    required this.enabled,
    this.live = false,
    this.openSeats = 0,
    this.stakes = 0,
    this.waiting = 0,
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
        live: (m['live'] ?? false) as bool,
        openSeats: (m['openSeats'] ?? 0) as int,
        stakes: (m['stakes'] ?? 0) as int,
        waiting: (m['waiting'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'address': address,
        'photoUrl': photoUrl,
        'hoursText': hoursText,
        'phone': phone,
        'enabled': enabled,
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
    bool? live,
    int? openSeats,
    int? stakes,
    int? waiting,
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
        live: live ?? this.live,
        openSeats: openSeats ?? this.openSeats,
        stakes: stakes ?? this.stakes,
        waiting: waiting ?? this.waiting,
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
          live == other.live &&
          openSeats == other.openSeats &&
          stakes == other.stakes &&
          waiting == other.waiting;

  @override
  int get hashCode => Object.hash(
      id, name, city, address, photoUrl, hoursText, phone, enabled, live, openSeats, stakes, waiting);
}
