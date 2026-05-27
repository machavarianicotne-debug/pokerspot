import 'dart:async';

import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/chat/domain/chat_repository.dart';
import 'package:pokerspot/features/chat/domain/message.dart';

/// In-memory [ChatRepository] for tests + offline UI work. No Firebase imports.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({List<Message>? seed}) {
    for (final m in seed ?? const <Message>[]) {
      _messages[m.id] = m;
    }
  }

  final _messages = <String, Message>{};
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

  int _byAt(Message a, Message b) =>
      (a.at?.millisecondsSinceEpoch ?? 0).compareTo(b.at?.millisecondsSinceEpoch ?? 0);

  @override
  Stream<List<Message>> watchThread({required String clubId, required String playerUid}) =>
      _watch(() => _messages.values
          .where((m) => m.clubId == clubId && m.playerUid == playerUid)
          .toList()
        ..sort(_byAt));

  @override
  Stream<List<ChatThread>> watchClubThreads(String clubId) => _watch(() {
        final byPlayer = <String, List<Message>>{};
        for (final m in _messages.values.where((m) => m.clubId == clubId)) {
          (byPlayer[m.playerUid] ??= []).add(m);
        }
        final threads = byPlayer.entries.map((e) {
          final msgs = e.value..sort(_byAt);
          final last = msgs.last;
          return ChatThread(
            clubId: clubId,
            playerUid: e.key,
            playerName: last.playerName,
            lastText: last.text,
            lastAt: last.at,
            unread: msgs.where((m) => m.fromPlayer && !m.read).length,
          );
        }).toList()
          ..sort((a, b) =>
              (b.lastAt?.millisecondsSinceEpoch ?? 0).compareTo(a.lastAt?.millisecondsSinceEpoch ?? 0));
        return threads;
      });

  @override
  Future<void> markThreadRead({
    required String clubId,
    required String playerUid,
    required bool asPit,
  }) async {
    for (final entry in _messages.entries.toList()) {
      final m = entry.value;
      if (m.clubId != clubId || m.playerUid != playerUid || m.read) continue;
      if (asPit ? m.fromPlayer : !m.fromPlayer) {
        _messages[entry.key] = Message(
          id: m.id, clubId: m.clubId, playerUid: m.playerUid, playerName: m.playerName,
          senderUid: m.senderUid, senderRole: m.senderRole, text: m.text, at: m.at, read: true,
          reactions: m.reactions,
        );
      }
    }
    _changes.add(null);
  }

  @override
  Stream<List<ChatThread>> watchPlayerThreads(String playerUid) => _watch(() {
        final byClub = <String, List<Message>>{};
        for (final m in _messages.values.where((m) => m.playerUid == playerUid)) {
          (byClub[m.clubId] ??= []).add(m);
        }
        final threads = byClub.entries.map((e) {
          final msgs = e.value..sort(_byAt);
          final last = msgs.last;
          return ChatThread(
            clubId: e.key,
            playerUid: playerUid,
            playerName: last.playerName,
            lastText: last.text,
            lastAt: last.at,
            unread: msgs.where((m) => !m.fromPlayer && !m.read).length,
          );
        }).toList()
          ..sort((a, b) =>
              (b.lastAt?.millisecondsSinceEpoch ?? 0).compareTo(a.lastAt?.millisecondsSinceEpoch ?? 0));
        return threads;
      });

  @override
  Future<void> send({
    required String clubId,
    required String playerUid,
    required String playerName,
    required String senderUid,
    required AppRole senderRole,
    required String text,
  }) async {
    final id = 'msg-${_seq++}';
    _messages[id] = Message(
      id: id,
      clubId: clubId,
      playerUid: playerUid,
      playerName: playerName,
      senderUid: senderUid,
      senderRole: senderRole,
      text: text,
      at: DateTime.now(),
    );
    _changes.add(null);
  }

  @override
  Future<void> setReaction({
    required String messageId,
    required String uid,
    required String emoji,
  }) async {
    final m = _messages[messageId];
    if (m == null) return;
    final next = Map<String, String>.from(m.reactions);
    if (emoji.isEmpty) {
      next.remove(uid);
    } else {
      next[uid] = emoji;
    }
    _messages[messageId] = Message(
      id: m.id, clubId: m.clubId, playerUid: m.playerUid, playerName: m.playerName,
      senderUid: m.senderUid, senderRole: m.senderRole, text: m.text, at: m.at, read: m.read,
      reactions: next,
    );
    _changes.add(null);
  }
}
