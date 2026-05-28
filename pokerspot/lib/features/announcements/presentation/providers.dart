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
