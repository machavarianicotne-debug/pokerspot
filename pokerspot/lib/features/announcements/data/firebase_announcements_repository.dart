import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/announcements/domain/announcement.dart';
import 'package:pokerspot/features/announcements/domain/announcements_repository.dart';

/// Firestore-backed [AnnouncementsRepository]. One subcollection per club
/// (`clubs/{clubId}/announcements`). All writes target the direct doc path
/// using the caller-supplied [clubId] — no collectionGroup lookups (those
/// would need a separate collectionGroup rule + an index just to map id→ref).
class FirebaseAnnouncementsRepository implements AnnouncementsRepository {
  FirebaseAnnouncementsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String clubId) =>
      _db.collection('clubs').doc(clubId).collection('announcements');

  DocumentReference<Map<String, dynamic>> _doc(String clubId, String id) =>
      _col(clubId).doc(id);

  Announcement _row(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = Map<String, dynamic>.from(d.data()!);
    final created = m['createdAt'];
    m['createdAt'] = created is Timestamp ? created.millisecondsSinceEpoch : created;
    final edited = m['editedAt'];
    m['editedAt'] = edited is Timestamp ? edited.millisecondsSinceEpoch : edited;
    return Announcement.fromMap(d.id, m);
  }

  int _byCreated(Announcement a, Announcement b) =>
      (a.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(b.createdAt?.millisecondsSinceEpoch ?? 0);

  @override
  Stream<List<Announcement>> watchByClub(String clubId) => _col(clubId)
      .snapshots()
      .map((s) => s.docs.map(_row).toList()..sort(_byCreated));

  @override
  Future<void> post({
    required String clubId,
    required String senderUid,
    required String senderName,
    required String text,
  }) =>
      _col(clubId).add({
        'clubId': clubId,
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'editedAt': null,
      });

  @override
  Future<void> edit({
    required String clubId,
    required String announcementId,
    required String newText,
  }) =>
      _doc(clubId, announcementId)
          .update({'text': newText, 'editedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> delete({required String clubId, required String announcementId}) =>
      _doc(clubId, announcementId).delete();

  @override
  Future<void> setReaction({
    required String clubId,
    required String announcementId,
    required String uid,
    required String emoji,
  }) =>
      _doc(clubId, announcementId).update({
        'reactions.$uid': emoji.isEmpty ? FieldValue.delete() : emoji,
      });
}
