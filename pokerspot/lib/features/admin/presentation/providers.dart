import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/admin/data/firebase_admin_repository.dart';
import 'package:pokerspot/features/admin/domain/admin_repository.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
    (ref) => FirebaseAdminRepository(FirebaseFirestore.instance));

/// Live recent audit-log entries (newest first). Gated on auth so the
/// admin-only query never runs before the session is ready.
final recentAuditProvider = StreamProvider<List<AuditEntry>>((ref) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <AuditEntry>[]);
  return ref.watch(adminRepositoryProvider).watchRecent(limit: 50);
});
