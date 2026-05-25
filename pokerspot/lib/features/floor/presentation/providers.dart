import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/firebase_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

final tablesRepositoryProvider = Provider<TablesRepository>(
    (ref) => FirebaseTablesRepository(FirebaseFirestore.instance));

final waitlistRepositoryProvider = Provider<WaitlistRepository>(
    (ref) => FirebaseWaitlistRepository(FirebaseFirestore.instance));

final sessionsRepositoryProvider = Provider<SessionsRepository>(
    (ref) => FirebaseSessionsRepository(FirebaseFirestore.instance));

final reservationsRepositoryProvider = Provider<ReservationsRepository>(
    (ref) => FirebaseReservationsRepository(FirebaseFirestore.instance));

// Club reads require signedIn() — gate on auth so a query never fires before
// the session is ready (avoids intermittent permission-denied after sign-in).

/// Tables for a club (ordered by number).
final tablesProvider = StreamProvider.family<List<PokerTable>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <PokerTable>[]);
  return ref.watch(tablesRepositoryProvider).watchTables(clubId);
});

/// A club's live active waitlist (Pit Boss view).
final clubWaitlistProvider = StreamProvider.family<List<WaitlistEntry>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <WaitlistEntry>[]);
  return ref.watch(waitlistRepositoryProvider).watchByClub(clubId);
});

/// The signed-in player's active waitlist entries (null uid -> empty).
final myWaitlistProvider = StreamProvider<List<WaitlistEntry>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <WaitlistEntry>[]);
  return ref.watch(waitlistRepositoryProvider).watchByPlayer(uid);
});

/// A club's live active sessions (Pit Boss view).
final clubSessionsProvider = StreamProvider.family<List<Session>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionsRepositoryProvider).watchActiveByClub(clubId);
});

/// All sessions for a club (active + ended) — Super Admin analytics.
final clubSessionsAllProvider = StreamProvider.family<List<Session>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionsRepositoryProvider).watchAllByClub(clubId);
});

/// The signed-in player's own active sessions (Activity tab; null uid -> empty).
final mySessionProvider = StreamProvider<List<Session>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionsRepositoryProvider).watchByPlayer(uid);
});

/// ALL of the signed-in player's sessions (active + ended) for playtime stats.
final myAllSessionsProvider = StreamProvider<List<Session>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <Session>[]);
  return ref.watch(sessionsRepositoryProvider).watchAllByPlayer(uid);
});

/// A club's active (held) reservations (Pit Boss view).
final clubReservationsProvider = StreamProvider.family<List<Reservation>, String>((ref, clubId) {
  if (ref.watch(uidProvider).valueOrNull == null) return Stream.value(const <Reservation>[]);
  return ref.watch(reservationsRepositoryProvider).watchByClub(clubId);
});

/// The signed-in player's active (held) reservations (null uid -> empty).
final myReservationsProvider = StreamProvider<List<Reservation>>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream.value(const <Reservation>[]);
  return ref.watch(reservationsRepositoryProvider).watchByPlayer(uid);
});
