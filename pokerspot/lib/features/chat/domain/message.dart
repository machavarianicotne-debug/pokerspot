// Chat domain — one 1-on-1 message between a player and a club's Pit Boss.
// Pure Dart, no Firebase imports. Flat top-level collection `messages/{id}`; a
// "thread" is all messages sharing a (clubId, playerUid) pair. `at` is epoch
// millis (the Firebase repo converts Firestore Timestamps <-> millis).

import 'package:pokerspot/features/auth/domain/app_user.dart';

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class Message {
  final String id;
  final String clubId;
  final String playerUid;
  final String playerName;
  final String senderUid;
  final AppRole senderRole;
  final String text;
  final DateTime? at;

  const Message({
    required this.id,
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.senderUid,
    required this.senderRole,
    required this.text,
    required this.at,
  });

  /// True when this message was sent by the player (vs the Pit Boss / admin).
  bool get fromPlayer => senderUid == playerUid;

  factory Message.fromMap(String id, Map<String, dynamic> m) => Message(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        playerUid: (m['playerUid'] ?? '') as String,
        playerName: (m['playerName'] ?? '') as String,
        senderUid: (m['senderUid'] ?? '') as String,
        senderRole: AppRole.fromString(m['senderRole'] as String?),
        text: (m['text'] ?? '') as String,
        at: _date(m['at']),
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'playerUid': playerUid,
        'playerName': playerName,
        'senderUid': senderUid,
        'senderRole': senderRole.asString,
        'text': text,
        'at': at?.millisecondsSinceEpoch,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          playerUid == other.playerUid &&
          playerName == other.playerName &&
          senderUid == other.senderUid &&
          senderRole == other.senderRole &&
          text == other.text &&
          at == other.at;

  @override
  int get hashCode =>
      Object.hash(id, clubId, playerUid, playerName, senderUid, senderRole, text, at);
}

/// A grouped conversation (one per player) for the Pit Boss inbox.
class ChatThread {
  final String clubId;
  final String playerUid;
  final String playerName;
  final String lastText;
  final DateTime? lastAt;
  final int unread;

  const ChatThread({
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.lastText,
    required this.lastAt,
    required this.unread,
  });
}
