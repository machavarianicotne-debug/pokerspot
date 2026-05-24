import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/admin/domain/admin_repository.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';

/// Firestore-backed [AdminRepository]. Entries live in `admin_audit_log`,
/// ordered by `at` (serverTimestamp) descending.
class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('admin_audit_log');

  @override
  Future<void> log({
    required String actorUid,
    required String action,
    required String target,
    Map<String, dynamic> meta = const {},
  }) {
    return _col.add({
      'actorUid': actorUid,
      'action': action,
      'target': target,
      'meta': meta,
      'at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AuditEntry>> watchRecent({int limit = 50}) => _col
      .orderBy('at', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final m = Map<String, dynamic>.from(d.data());
            final at = m['at'];
            m['at'] = at is Timestamp ? at.millisecondsSinceEpoch : at;
            return AuditEntry.fromMap(d.id, m);
          }).toList());
}
