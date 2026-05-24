import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/firebase_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

final tablesRepositoryProvider = Provider<TablesRepository>(
    (ref) => FirebaseTablesRepository(FirebaseFirestore.instance));

final waitlistRepositoryProvider = Provider<WaitlistRepository>(
    (ref) => FirebaseWaitlistRepository(FirebaseFirestore.instance));

final sessionsRepositoryProvider = Provider<SessionsRepository>(
    (ref) => FirebaseSessionsRepository(FirebaseFirestore.instance));

/// Tables for a club (ordered by number).
final tablesProvider = StreamProvider.family<List<PokerTable>, String>(
    (ref, clubId) => ref.watch(tablesRepositoryProvider).watchTables(clubId));

/// A club's live active waitlist (Pit Boss view).
final clubWaitlistProvider = StreamProvider.family<List<WaitlistEntry>, String>(
    (ref, clubId) => ref.watch(waitlistRepositoryProvider).watchByClub(clubId));

/// The signed-in player's active waitlist entries (null uid -> empty).
final myWaitlistProvider = StreamProvider<List<WaitlistEntry>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <WaitlistEntry>[]);
  return ref.watch(waitlistRepositoryProvider).watchByPlayer(uid);
});

/// A club's live active sessions (Pit Boss view).
final clubSessionsProvider = StreamProvider.family<List<Session>, String>(
    (ref, clubId) => ref.watch(sessionsRepositoryProvider).watchActiveByClub(clubId));
