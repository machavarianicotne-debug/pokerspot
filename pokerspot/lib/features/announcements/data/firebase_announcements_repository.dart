import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/announcements/domain/announcement.dart';
import 'package:pokerspot/features/announcements/domain/announcements_repository.dart';

/// Firestore-backed [AnnouncementsRepository]. One subcollection per club
/// (`clubs/{clubId}/announcements`). Sort done client-side so no composite
/// index is needed; reactions are nested under a single `reactions.{uid}` field.
class FirebaseAnnouncementsRepository implements AnnouncementsRepository {
  FirebaseAnnouncementsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String clubId) =>
      _db.collection('clubs').doc(clubId).collection('announcements');

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
  Future<void> edit({required String announcementId, required String newText}) async {
    final ref = await _findDocRef(announcementId);
    if (ref == null) return;
    await ref.update({'text': newText, 'editedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> delete(String announcementId) async {
    final ref = await _findDocRef(announcementId);
    if (ref == null) return;
    await ref.delete();
  }

  @override
  Future<void> setReaction({
    required String announcementId,
    required String uid,
    required String emoji,
  }) async {
    final ref = await _findDocRef(announcementId);
    if (ref == null) return;
    await ref.update({
      'reactions.$uid': emoji.isEmpty ? FieldValue.delete() : emoji,
    });
  }

  /// Find an announcement doc by id via a collection-group lookup. Since ids
  /// are globally unique (Firestore-generated), one document matches.
  Future<DocumentReference<Map<String, dynamic>>?> _findDocRef(String id) async {
    final snap = await _db.collectionGroup('announcements').get();
    for (final d in snap.docs) {
      if (d.id == id) return d.reference;
    }
    return null;
  }
}
