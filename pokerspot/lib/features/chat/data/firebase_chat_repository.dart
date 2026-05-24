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
            unread: 0,
          );
        }).toList()
          ..sort((a, b) => (b.lastAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(a.lastAt?.millisecondsSinceEpoch ?? 0));
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
}
