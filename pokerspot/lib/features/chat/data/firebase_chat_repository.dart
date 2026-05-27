import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/chat/domain/chat_repository.dart';
import 'package:pokerspot/features/chat/domain/message.dart';

/// Firestore-backed [ChatRepository]. Flat `messages` collection; a thread is
/// all docs sharing (clubId, playerUid). Status/sort done client-side so only
/// single-field indexes are needed.
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('messages');

  Message _msg(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    final at = m['at'];
    m['at'] = at is Timestamp ? at.millisecondsSinceEpoch : at;
    return Message.fromMap(d.id, m);
  }

  int _byAt(Message a, Message b) =>
      (a.at?.millisecondsSinceEpoch ?? 0).compareTo(b.at?.millisecondsSinceEpoch ?? 0);

  @override
  Stream<List<Message>> watchThread({required String clubId, required String playerUid}) => _col
      .where('clubId', isEqualTo: clubId)
      .where('playerUid', isEqualTo: playerUid)
      .snapshots()
      .map((s) => s.docs.map(_msg).toList()..sort(_byAt));

  @override
  Stream<List<ChatThread>> watchClubThreads(String clubId) =>
      _col.where('clubId', isEqualTo: clubId).snapshots().map((s) {
        final byPlayer = <String, List<Message>>{};
        for (final m in s.docs.map(_msg)) {
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
            // Unread for the Pit Boss = the player's messages not yet read.
            unread: msgs.where((m) => m.fromPlayer && !m.read).length,
          );
        }).toList()
          ..sort((a, b) => (b.lastAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(a.lastAt?.millisecondsSinceEpoch ?? 0));
        return threads;
      });

  @override
  Stream<List<ChatThread>> watchPlayerThreads(String playerUid) =>
      _col.where('playerUid', isEqualTo: playerUid).snapshots().map((s) {
        final byClub = <String, List<Message>>{};
        for (final m in s.docs.map(_msg)) {
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
            // Unread for the player = the Pit Boss's messages not yet read.
            unread: msgs.where((m) => !m.fromPlayer && !m.read).length,
          );
        }).toList()
          ..sort((a, b) => (b.lastAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(a.lastAt?.millisecondsSinceEpoch ?? 0));
        return threads;
      });

  @override
  Future<void> markThreadRead({
    required String clubId,
    required String playerUid,
    required bool asPit,
  }) async {
    final snap = await _col
        .where('clubId', isEqualTo: clubId)
        .where('playerUid', isEqualTo: playerUid)
        .get();
    final batch = _db.batch();
    var any = false;
    for (final d in snap.docs) {
      final m = _msg(d);
      if (m.read) continue;
      // Pit reads the player's messages; player reads the staff's messages.
      if (asPit ? m.fromPlayer : !m.fromPlayer) {
        batch.update(d.reference, {'read': true});
        any = true;
      }
    }
    if (any) await batch.commit();
  }

  @override
  Future<void> send({
    required String clubId,
    required String playerUid,
    required String playerName,
    required String senderUid,
    required AppRole senderRole,
    required String text,
  }) {
    return _col.add({
      'clubId': clubId,
      'playerUid': playerUid,
      'playerName': playerName,
      'senderUid': senderUid,
      'senderRole': senderRole.asString,
      'text': text,
      'at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setReaction({
    required String messageId,
    required String uid,
    required String emoji,
  }) =>
      _col.doc(messageId).update({
        'reactions.$uid': emoji.isEmpty ? FieldValue.delete() : emoji,
      });
}
