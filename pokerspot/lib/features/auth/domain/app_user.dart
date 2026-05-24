// Auth domain model (spec §12). Pure Dart — no Firebase imports.

enum AppRole {
  player,
  pitboss,
  superadmin;

  static AppRole fromString(String? raw) {
    switch (raw) {
      case 'superadmin':
        return AppRole.superadmin;
      case 'pitboss':
        return AppRole.pitboss;
      default:
        return AppRole.player;
    }
  }

  String get asString => name;
}

class AppUser {
  final String uid;
  final String phone;
  final String displayName;
  final AppRole role;

  /// BCP-47 UI language code. Allowed values: 'ka' | 'en' | 'ru'.
  /// Matches Plan 1 i18n (AppL10n.supportedLocales). Stored as a plain string
  /// for clean Firestore serialization (no custom Locale enum).
  final String lang;
  final bool blocked;

  const AppUser({
    required this.uid,
    required this.phone,
    required this.displayName,
    required this.role,
    required this.lang,
    required this.blocked,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        phone: (m['phone'] ?? '') as String,
        displayName: (m['displayName'] ?? '') as String,
        role: AppRole.fromString(m['role'] as String?),
        lang: (m['lang'] ?? 'en') as String,
        blocked: (m['blocked'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'displayName': displayName,
        'role': role.asString,
        'lang': lang,
        'blocked': blocked,
      };

  AppUser copyWith({
    String? uid,
    String? phone,
    String? displayName,
    AppRole? role,
    String? lang,
    bool? blocked,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        lang: lang ?? this.lang,
        blocked: blocked ?? this.blocked,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          phone == other.phone &&
          displayName == other.displayName &&
          role == other.role &&
          lang == other.lang &&
          blocked == other.blocked;

  @override
  int get hashCode => Object.hash(uid, phone, displayName, role, lang, blocked);
}
