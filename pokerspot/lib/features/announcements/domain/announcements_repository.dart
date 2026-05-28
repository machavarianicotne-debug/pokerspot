// Announcements repository interface. Pure Dart — no Firebase imports.

import 'package:pokerspot/features/announcements/domain/announcement.dart';

abstract interface class AnnouncementsRepository {
  /// Live announcements for a club, oldest first (chat bubbles read top-to-bottom).
  Stream<List<Announcement>> watchByClub(String clubId);

  /// Pit Boss posts a new announcement. Stamps createdAt server-side.
  Future<void> post({
    required String clubId,
    required String senderUid,
    required String senderName,
    required String text,
  });

  /// Pit Boss edits their own post. Stamps editedAt.
  Future<void> edit({
    required String clubId,
    required String announcementId,
    required String newText,
  });

  /// Pit Boss deletes their own post.
  Future<void> delete({required String clubId, required String announcementId});

  /// Set (or, with empty [emoji], clear) the caller's emoji reaction.
  Future<void> setReaction({
    required String clubId,
    required String announcementId,
    required String uid,
    required String emoji,
  });
}
