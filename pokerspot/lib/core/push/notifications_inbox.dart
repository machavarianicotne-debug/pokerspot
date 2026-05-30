import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

/// One in-app notification shown in the player's Activity tab. Written
/// server-side by the Cloud Functions (a seat opened, a reservation ending) and
/// read here. Shown RED until [seen]; carries the [clubName] it came from.
class PsNotification {
  const PsNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.clubName,
    required this.seen,
    required this.createdAtMillis,
  });

  final String id;
  final String title;
  final String body;
  final String clubName;
  final bool seen;
  final int createdAtMillis;

  factory PsNotification.fromMap(String id, Map<String, dynamic> m) => PsNotification(
        id: id,
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        clubName: (m['clubName'] ?? '') as String,
        seen: (m['seen'] ?? false) as bool,
        createdAtMillis: m['createdAt'] is Timestamp
            ? (m['createdAt'] as Timestamp).millisecondsSinceEpoch
            : (m['createdAt'] is int ? m['createdAt'] as int : 0),
      );
}

class NotificationsRepository {
  NotificationsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('notifications');

  /// A player's notifications, newest first (sorted client-side so only the
  /// single-field `uid` index is needed — no composite index to provision).
  Stream<List<PsNotification>> watchByPlayer(String uid) => _col
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => PsNotification.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis)));

  /// Mark a notification read (the player saw it) — clears the red state.
  Future<void> markSeen(String id) => _col.doc(id).update({'seen': true});
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(FirebaseFirestore.instance));

/// The signed-in player's in-app notifications, newest first (null uid -> empty).
final myNotificationsProvider = StreamProvider<List<PsNotification>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <PsNotification>[]);
  return ref.watch(notificationsRepositoryProvider).watchByPlayer(uid);
});
