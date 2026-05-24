// Chat domain repository interface. Pure Dart — no Firebase imports.

import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/chat/domain/message.dart';

abstract interface class ChatRepository {
  /// Live messages in one player↔club thread, oldest first.
  Stream<List<Message>> watchThread({required String clubId, required String playerUid});

  /// Live per-player threads for a club (Pit Boss inbox), newest activity first.
  Stream<List<ChatThread>> watchClubThreads(String clubId);

  /// Send a message into a thread.
  Future<void> send({
    required String clubId,
    required String playerUid,
    required String playerName,
    required String senderUid,
    required AppRole senderRole,
    required String text,
  });
}
