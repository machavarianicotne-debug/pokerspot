import 'dart:async';

import 'package:pokerspot/features/admin/domain/admin_repository.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';

/// In-memory [AdminRepository] for tests + offline UI work. No Firebase imports.
class FakeAdminRepository implements AdminRepository {
  final _entries = <AuditEntry>[];
  final _controller = StreamController<List<AuditEntry>>.broadcast();
  int _seq = 0;

  List<AuditEntry> _recent(int limit) => _entries.reversed.take(limit).toList();

  @override
  Future<void> log({
    required String actorUid,
    required String action,
    required String target,
    Map<String, dynamic> meta = const {},
  }) async {
    _entries.add(AuditEntry(
      id: 'audit-${_seq++}',
      actorUid: actorUid,
      action: action,
      target: target,
      meta: meta,
      at: DateTime.now(),
    ));
    _controller.add(_recent(50));
  }

  @override
  Stream<List<AuditEntry>> watchRecent({int limit = 50}) async* {
    yield _recent(limit);
    yield* _controller.stream;
  }
}
