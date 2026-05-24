// Admin domain — an audit-log entry (Plan 6). Pure Dart, no Firebase imports.
// Top-level collection admin_audit_log/{id}. `at` is epoch millis (the Firebase
// repo converts Firestore Timestamp <-> millis).

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class AuditEntry {
  final String id;
  final String actorUid;
  final String action;
  final String target;
  final Map<String, dynamic> meta;
  final DateTime? at;

  const AuditEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.target,
    this.meta = const {},
    this.at,
  });

  factory AuditEntry.fromMap(String id, Map<String, dynamic> m) => AuditEntry(
        id: id,
        actorUid: (m['actorUid'] ?? '') as String,
        action: (m['action'] ?? '') as String,
        target: (m['target'] ?? '') as String,
        meta: (m['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
        at: _date(m['at']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          actorUid == other.actorUid &&
          action == other.action &&
          target == other.target &&
          at == other.at;

  @override
  int get hashCode => Object.hash(id, actorUid, action, target, at);
}
