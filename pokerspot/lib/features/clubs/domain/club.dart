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

  const Club({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.photoUrl,
    required this.hoursText,
    required this.phone,
    required this.enabled,
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
          enabled == other.enabled;

  @override
  int get hashCode =>
      Object.hash(id, name, city, address, photoUrl, hoursText, phone, enabled);
}
