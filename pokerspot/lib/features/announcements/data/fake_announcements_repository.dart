import 'dart:async';

import 'package:pokerspot/features/announcements/domain/announcement.dart';
import 'package:pokerspot/features/announcements/domain/announcements_repository.dart';

/// In-memory [AnnouncementsRepository] for tests + offline UI work. Mirrors the
/// chat fake's shape (broadcast stream, sequential ids).
class FakeAnnouncementsRepository implements AnnouncementsRepository {
  FakeAnnouncementsRepository({List<Announcement>? seed}) {
    for (final a in seed ?? const <Announcement>[]) {
      _items[a.id] = a;
    }
  }

  final _items = <String, Announcement>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  Stream<T> _watch<T>(T Function() read) {
    final out = StreamController<T>();
    StreamSubscription<void>? sub;
    out.onListen = () {
      out.add(read());
      sub = _changes.stream.listen((_) => out.add(read()));
    };
    out.onCancel = () async => sub?.cancel();
    return out.stream;
  }

  int _byCreated(Announcement a, Announcement b) =>
      (a.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(b.createdAt?.millisecondsSinceEpoch ?? 0);

  @override
  Stream<List<Announcement>> watchByClub(String clubId) => _watch(() =>
      _items.values.where((a) => a.clubId == clubId).toList()..sort(_byCreated));

  @override
  Future<void> post({
    required String clubId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final id = 'ann-${_seq++}';
    _items[id] = Announcement(
      id: id,
      clubId: clubId,
      senderUid: senderUid,
      senderName: senderName,
      text: text,
      createdAt: DateTime.now(),
      editedAt: null,
    );
    _changes.add(null);
  }

  @override
  Future<void> edit({required String announcementId, required String newText}) async {
    final a = _items[announcementId];
    if (a == null) return;
    _items[announcementId] = Announcement(
      id: a.id,
      clubId: a.clubId,
      senderUid: a.senderUid,
      senderName: a.senderName,
      text: newText,
      createdAt: a.createdAt,
      editedAt: DateTime.now(),
      reactions: a.reactions,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete(String announcementId) async {
    _items.remove(announcementId);
    _changes.add(null);
  }

  @override
  Future<void> setReaction({
    required String announcementId,
    required String uid,
    required String emoji,
  }) async {
    final a = _items[announcementId];
    if (a == null) return;
    final next = Map<String, String>.from(a.reactions);
    if (emoji.isEmpty) {
      next.remove(uid);
    } else {
      next[uid] = emoji;
    }
    _items[announcementId] = Announcement(
      id: a.id,
      clubId: a.clubId,
      senderUid: a.senderUid,
      senderName: a.senderName,
      text: a.text,
      createdAt: a.createdAt,
      editedAt: a.editedAt,
      reactions: next,
    );
    _changes.add(null);
  }
}
