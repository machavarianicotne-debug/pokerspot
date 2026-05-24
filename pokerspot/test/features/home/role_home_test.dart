import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/role_home.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';

const _demo = Club(
  id: 'demo',
  name: 'Demo Club',
  city: 'Tbilisi',
  address: 'A',
  photoUrl: null,
  hoursText: 'H',
  phone: 'P',
  enabled: true,
);

void main() {
  testWidgets('player profile renders the Player home (clubs list)', (tester) async {
    final auth = FakeAuthRepository();
    final users = FakeUsersRepository();
    final s = await auth.sendOtp('+995555222222');
    await auth.confirmOtp(s, '222222');
    await users.createProfile(
        uid: auth.currentUid!, phone: '', firstName: 'Sandro', lastName: 'Beridze', lang: 'en');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        usersRepositoryProvider.overrideWithValue(users),
        clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: const [_demo])),
        // Activity tab is built (offstage) by the IndexedStack — keep its
        // streams off Firebase.
        myWaitlistProvider.overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
        mySessionProvider.overrideWith((ref) => Stream.value(const <Session>[])),
        myReservationsProvider.overrideWith((ref) => Stream.value(const <Reservation>[])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: RoleHome(),
      ),
    ));
    await tester.pumpAndSettle();

    // Player role -> PlayerHome -> ClubsListScreen.
    expect(find.byType(PsBrand), findsOneWidget); // PlayerHome brand nav
    expect(find.text('Demo Club'), findsOneWidget); // the seeded club card
  });
}
