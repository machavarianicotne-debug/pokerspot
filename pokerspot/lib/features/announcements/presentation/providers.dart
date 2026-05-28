import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/announcements/data/firebase_announcements_repository.dart';
import 'package:pokerspot/features/announcements/domain/announcement.dart';
import 'package:pokerspot/features/announcements/domain/announcements_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
    (ref) => FirebaseAnnouncementsRepository(FirebaseFirestore.instance));

/// Live announcements for a club (oldest first).
final clubAnnouncementsProvider =
    StreamProvider.family<List<Announcement>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Announcement>[]);
  return ref.watch(announcementsRepositoryProvider).watchByClub(clubId);
});

/// Unread Club Chat count for a given club: announcements with createdAt newer
/// than the current user's `lastSeenClubChats[clubId]`. A missing key counts
/// every announcement as unread. Signed-out → 0.
final clubChatUnreadCountProvider = Provider.family<int, String>((ref, clubId) {
  final list = ref.watch(clubAnnouncementsProvider(clubId)).valueOrNull ??
      const <Announcement>[];
  if (list.isEmpty) return 0;
  final user = ref.watch(currentUserProvider).valueOrNull;
  final lastSeen = user?.lastSeenClubChats[clubId];
  return list.where((a) {
    final at = a.createdAt;
    if (at == null) return false;
    return lastSeen == null || at.isAfter(lastSeen);
  }).length;
});
