import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/data/firebase_chat_repository.dart';
import 'package:pokerspot/features/chat/domain/chat_repository.dart';
import 'package:pokerspot/features/chat/domain/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
    (ref) => FirebaseChatRepository(FirebaseFirestore.instance));

/// (clubId, playerUid) thread key for [threadProvider].
typedef ThreadKey = ({String clubId, String playerUid});

/// Live messages in one player↔club thread.
final threadProvider = StreamProvider.family<List<Message>, ThreadKey>(
    (ref, k) => ref.watch(chatRepositoryProvider).watchThread(clubId: k.clubId, playerUid: k.playerUid));

/// Live per-player threads for a club (Pit Boss inbox).
final clubThreadsProvider = StreamProvider.family<List<ChatThread>, String>(
    (ref, clubId) => ref.watch(chatRepositoryProvider).watchClubThreads(clubId));

/// Live per-club threads for the signed-in player (player chat inbox).
final myThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <ChatThread>[]);
  return ref.watch(chatRepositoryProvider).watchPlayerThreads(uid);
});
