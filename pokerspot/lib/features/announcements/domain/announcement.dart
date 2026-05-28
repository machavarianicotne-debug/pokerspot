// Announcements domain — one Pit Boss broadcast post in a club's Club Chat.
// Pure Dart, no Firebase imports. Lives at clubs/{clubId}/announcements/{id};
// timestamps are stored as epoch millis (the Firebase repo converts Firestore
// Timestamps <-> millis), mirroring the chat Message pattern.

DateTime? _date(dynamic millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis as int);

class Announcement {
  final String id;
  final String clubId;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime? createdAt;
  final DateTime? editedAt;

  /// Emoji reactions keyed by reactor uid (one emoji per user; '' never stored).
  final Map<String, String> reactions;

  const Announcement({
    required this.id,
    required this.clubId,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.editedAt,
    this.reactions = const {},
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> m) => Announcement(
        id: id,
        clubId: (m['clubId'] ?? '') as String,
        senderUid: (m['senderUid'] ?? '') as String,
        senderName: (m['senderName'] ?? '') as String,
        text: (m['text'] ?? '') as String,
        createdAt: _date(m['createdAt']),
        editedAt: _date(m['editedAt']),
        reactions: (m['reactions'] as Map?)
                ?.map((k, v) => MapEntry(k as String, '$v')) ??
            const {},
      );

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'editedAt': editedAt?.millisecondsSinceEpoch,
        'reactions': reactions,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clubId == other.clubId &&
          senderUid == other.senderUid &&
          senderName == other.senderName &&
          text == other.text &&
          createdAt == other.createdAt &&
          editedAt == other.editedAt &&
          _mapEq(reactions, other.reactions);

  // hashCode intentionally omits [reactions] (Map) — mirrors Message.hashCode.
  @override
  int get hashCode =>
      Object.hash(id, clubId, senderUid, senderName, text, createdAt, editedAt);
}

bool _mapEq(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
