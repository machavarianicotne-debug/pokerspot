// Auth domain model (spec §12). Pure Dart — no Firebase imports.

enum AppRole {
  player,
  pitboss,
  superadmin;

  /// Parse a stored role string. Canonical wire format is snake_case
  /// (`super_admin` / `pit_boss` / `player`), but we also accept the legacy
  /// enum-name form (`superadmin` / `pitboss`) so older docs keep working.
  /// Unknown / null -> player (safe default).
  static AppRole fromString(String? raw) {
    switch (raw) {
      case 'super_admin':
      case 'superadmin':
        return AppRole.superadmin;
      case 'pit_boss':
      case 'pitboss':
        return AppRole.pitboss;
      default:
        return AppRole.player;
    }
  }

  /// Canonical snake_case wire format written to Firestore + matched by the
  /// security rules (`super_admin` / `pit_boss` / `player`).
  String get asString {
    switch (this) {
      case AppRole.superadmin:
        return 'super_admin';
      case AppRole.pitboss:
        return 'pit_boss';
      case AppRole.player:
        return 'player';
    }
  }
}

class AppUser {
  final String uid;
  final String phone;
  final String firstName;
  final String lastName;
  final AppRole role;

  /// BCP-47 UI language code. Allowed values: 'ka' | 'en' | 'ru'.
  /// Matches Plan 1 i18n (AppL10n.supportedLocales). Stored as a plain string
  /// for clean Firestore serialization (no custom Locale enum).
  final String lang;
  final bool blocked;

  /// Club this user staffs as Pit Boss (null for players / unassigned).
  /// The Pit Boss waitlist screen uses this; set it in the Firestore Console
  /// for now (Super Admin staff management is a later plan).
  final String? clubId;

  /// Last time this user opened each club's broadcast feed, keyed by clubId.
  /// Drives the Club Chat unread badge: any announcement with createdAt newer
  /// than the value here is unread. Persisted as `{clubId: epochMillis}` in
  /// Firestore; missing keys mean "never opened" → all posts count as unread.
  final Map<String, DateTime> lastSeenClubChats;

  const AppUser({
    required this.uid,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.lang,
    required this.blocked,
    this.clubId,
    this.lastSeenClubChats = const {},
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        phone: (m['phone'] ?? '') as String,
        // Default missing fields to '' for legacy docs written before the
        // displayName -> firstName/lastName split.
        firstName: (m['firstName'] ?? '') as String,
        lastName: (m['lastName'] ?? '') as String,
        role: AppRole.fromString(m['role'] as String?),
        lang: (m['lang'] ?? 'en') as String,
        blocked: (m['blocked'] ?? false) as bool,
        // Null for legacy users without a club assignment.
        clubId: m['clubId'] as String?,
        lastSeenClubChats: _readLastSeenMap(m['lastSeenClubChats']),
      );

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.asString,
        'lang': lang,
        'blocked': blocked,
        'clubId': clubId,
        'lastSeenClubChats': {
          for (final e in lastSeenClubChats.entries)
            e.key: e.value.millisecondsSinceEpoch,
        },
      };

  AppUser copyWith({
    String? uid,
    String? phone,
    String? firstName,
    String? lastName,
    AppRole? role,
    String? lang,
    bool? blocked,
    String? clubId,
    Map<String, DateTime>? lastSeenClubChats,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        phone: phone ?? this.phone,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role ?? this.role,
        lang: lang ?? this.lang,
        blocked: blocked ?? this.blocked,
        clubId: clubId ?? this.clubId,
        lastSeenClubChats: lastSeenClubChats ?? this.lastSeenClubChats,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          phone == other.phone &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          role == other.role &&
          lang == other.lang &&
          blocked == other.blocked &&
          clubId == other.clubId &&
          _mapEq(lastSeenClubChats, other.lastSeenClubChats);

  // hashCode omits [lastSeenClubChats] (Map) — mirrors Announcement.hashCode.
  @override
  int get hashCode =>
      Object.hash(uid, phone, firstName, lastName, role, lang, blocked, clubId);
}

Map<String, DateTime> _readLastSeenMap(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, DateTime>{};
  raw.forEach((k, v) {
    if (k is String && v is int) {
      out[k] = DateTime.fromMillisecondsSinceEpoch(v);
    }
  });
  return out;
}

bool _mapEq(Map<String, DateTime> a, Map<String, DateTime> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
