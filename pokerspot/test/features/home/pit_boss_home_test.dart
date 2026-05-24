import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_home.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

AppUser _pb({String? clubId}) => AppUser(
      uid: 'pb',
      phone: '',
      firstName: 'Pit',
      lastName: 'Boss',
      role: AppRole.pitboss,
      lang: 'en',
      blocked: false,
      clubId: clubId,
    );

WaitlistEntry _entry(String id, WaitlistStatus status) => WaitlistEntry(
      id: id,
      clubId: 'vake',
      playerUid: 'u',
      playerName: 'Nino K',
      stakes: _stakes,
      status: status,
      createdAt: DateTime.now(),
      calledAt: null,
    );

// Stable: currentUser + the waitlist family value are single-shot Stream.value.
Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ...overrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: PitBossHome(),
      ),
    );

void main() {
  testWidgets('no club assigned -> shows the message', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No club is assigned to your account'), findsOneWidget);
  });

  testWidgets('with a club -> lists waiting players with a Call button', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb(clubId: 'vake'))),
      clubWaitlistProvider('vake')
          .overrideWith((ref) => Stream.value([_entry('e1', WaitlistStatus.waiting)])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Nino K'), findsOneWidget);
    expect(find.byKey(const Key('callBtn_e1')), findsOneWidget);
  });

  testWidgets('a called entry shows the called status (no Call button)', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb(clubId: 'vake'))),
      clubWaitlistProvider('vake')
          .overrideWith((ref) => Stream.value([_entry('e2', WaitlistStatus.called)])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text("You've been called!"), findsOneWidget);
    expect(find.byKey(const Key('callBtn_e2')), findsNothing);
  });

  testWidgets('tapping Call moves the entry to called in the repo', (tester) async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    await wl.join(clubId: 'vake', playerUid: 'u', playerName: 'Nino K', stakes: _stakes);
    final entry = store.waitlist.values.first;

    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb(clubId: 'vake'))),
      clubWaitlistProvider('vake').overrideWith((ref) => Stream.value([entry])),
      waitlistRepositoryProvider.overrideWithValue(wl),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('callBtn_${entry.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.waitlist[entry.id]!.status, WaitlistStatus.called);
    expect(store.waitlist[entry.id]!.calledAt, isNotNull);
  });
}
