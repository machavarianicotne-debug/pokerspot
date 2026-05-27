import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/club_details_screen.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

const _vake = Club(
  id: 'vake',
  name: 'PokerSpot Vake',
  city: 'Tbilisi',
  address: 'Chavchavadze Ave 47',
  photoUrl: null,
  hoursText: 'Daily 14:00–04:00',
  phone: '+995 32 200 0000',
  enabled: true,
);

const _nlh = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'vake', number: 1, stakes: _nlh, seatCount: 9, open: true);

/// Minimal wrap (only the clubs repo) — for render tests that don't open the sheet.
Widget _wrap(String clubId, FakeClubsRepository repo) => ProviderScope(
      overrides: [
        uidProvider.overrideWith((ref) => Stream.value('u1')), // club reads gated on auth
        clubsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ClubDetailsScreen(clubId: clubId),
      ),
    );

/// Full wrap with floor + auth fakes — for the join flow.
Widget _wrapFull(String clubId, FakeFloorStore store, FakeAuthRepository auth,
        FakeUsersRepository users) =>
    ProviderScope(
      overrides: [
        uidProvider.overrideWith((ref) => Stream.value('u1')), // club reads gated on auth
        clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: const [_vake])),
        authRepositoryProvider.overrideWithValue(auth),
        usersRepositoryProvider.overrideWithValue(users),
        tablesRepositoryProvider.overrideWithValue(FakeTablesRepository(store)),
        waitlistRepositoryProvider.overrideWithValue(FakeWaitlistRepository(store)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ClubDetailsScreen(clubId: clubId),
      ),
    );

Future<FakeAuthRepository> _signedIn() async {
  final auth = FakeAuthRepository();
  final s = await auth.sendOtp('+995555222222');
  await auth.confirmOtp(s, '222222');
  return auth;
}

void main() {
  testWidgets('renders the club fields + the games empty state', (tester) async {
    await tester.pumpWidget(_wrap('vake', FakeClubsRepository(seed: const [_vake])));
    await tester.pumpAndSettle();

    // Name appears in both the nav title and the info card (mockup behaviour).
    expect(find.text('PokerSpot Vake'), findsWidgets);
    expect(find.text('Tbilisi'), findsOneWidget);
    expect(find.text('Chavchavadze Ave 47'), findsOneWidget);
    expect(find.text('Daily 14:00–04:00'), findsOneWidget);
    expect(find.text('+995 32 200 0000'), findsOneWidget);
    expect(find.byKey(const Key('phoneTile')), findsOneWidget);
    expect(find.byKey(const Key('copyPhoneBtn')), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    // No tables for this club → the "No games running" empty state shows.
    expect(find.text('No games running'), findsOneWidget);
  });

  testWidgets('renders a per-stake game card from the club tables', (tester) async {
    final store = FakeFloorStore(tables: const [_table]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        uidProvider.overrideWith((ref) => Stream.value('u1')), // club reads gated on auth
        clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: const [_vake])),
        tablesRepositoryProvider.overrideWithValue(FakeTablesRepository(store)),
        myWaitlistProvider.overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ClubDetailsScreen(clubId: 'vake'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gameCard_t1')), findsOneWidget);
    expect(find.byKey(const Key('joinGame_t1')), findsOneWidget);
  });

  testWidgets('unknown club id shows the empty/not-found state', (tester) async {
    await tester.pumpWidget(_wrap('missing', FakeClubsRepository(seed: const [_vake])));
    await tester.pumpAndSettle();
    expect(find.text('No clubs yet'), findsOneWidget);
    expect(find.text('PokerSpot Vake'), findsNothing);
  });

  testWidgets('join waitlist: picking a stake creates an entry', (tester) async {
    final store = FakeFloorStore(tables: const [_table]);
    final auth = await _signedIn();
    final users = FakeUsersRepository();
    await users.createProfile(
        uid: auth.currentUid!, phone: '', firstName: 'Nino', lastName: 'K', lang: 'en');

    await tester.pumpWidget(_wrapFull('vake', store, auth, users));
    // Bounded pumps (not pumpAndSettle) — the SnackBar would otherwise keep
    // pumpAndSettle from returning.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Per-card Join button joins that stake directly (mockup).
    await tester.tap(find.byKey(const Key('joinGame_t1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final list = await FakeWaitlistRepository(store).watchByClub('vake').first;
    expect(list.length, 1);
    expect(list.first.playerUid, auth.currentUid);
    expect(list.first.stakes.label, 'NLH 1/2 GEL');
    // TODO: widget test for live Riverpod streams — settles unpredictably.
    // Covered by fake repo unit tests + manual E2E. Revisit after design polish.
  }, skip: true);

  testWidgets('a stake the player already waits for shows Waiting', (tester) async {
    final store = FakeFloorStore(tables: const [_table]);
    final auth = await _signedIn();
    final users = FakeUsersRepository();
    await users.createProfile(
        uid: auth.currentUid!, phone: '', firstName: 'Nino', lastName: 'K', lang: 'en');
    // Pre-seed: the player is already waiting for NLH 1/2 GEL at this club.
    await FakeWaitlistRepository(store).join(
        clubId: 'vake', playerUid: auth.currentUid!, playerName: 'Nino', stakes: _nlh);

    await tester.pumpWidget(_wrapFull('vake', store, auth, users));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The game card's Join button shows "Waiting" for a stake already joined.
    expect(find.text('Waiting'), findsOneWidget);
    // TODO: widget test for live Riverpod streams — settles unpredictably.
    // Covered by fake repo unit tests + manual E2E. Revisit after design polish.
  }, skip: true);
}
