// Admin domain repository interface (Plan 6). Pure Dart — no Firebase imports.

import 'package:pokerspot/features/admin/domain/audit_entry.dart';

abstract interface class AdminRepository {
  /// Append an audit entry (who did what to whom, when).
  Future<void> log({
    required String actorUid,
    required String action,
    required String target,
    Map<String, dynamic> meta,
  });

  /// Live recent audit entries, newest first.
  Stream<List<AuditEntry>> watchRecent({int limit});
}
