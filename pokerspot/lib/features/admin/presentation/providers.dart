import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/admin/data/firebase_admin_repository.dart';
import 'package:pokerspot/features/admin/domain/admin_repository.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
    (ref) => FirebaseAdminRepository(FirebaseFirestore.instance));

/// Live recent audit-log entries (newest first).
final recentAuditProvider = StreamProvider<List<AuditEntry>>(
    (ref) => ref.watch(adminRepositoryProvider).watchRecent(limit: 50));
