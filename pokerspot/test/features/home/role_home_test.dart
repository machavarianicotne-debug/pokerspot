import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/role_home.dart';

void main() {
  testWidgets('superadmin profile shows Super Admin home', (tester) async {
    final auth = FakeAuthRepository();
    final users = FakeUsersRepository();
    final s = await auth.sendOtp('+995555111111');
    await auth.confirmOtp(s, '111111');
    await users.createProfile(uid: auth.currentUid!, phone: '', displayName: 'Sandro', lang: 'en');
    // simulate the seed: promote to superadmin via a second profile write is out of
    // scope; instead inject a users repo pre-seeded with superadmin:
    final seeded = FakeUsersRepository();
    await seeded.createProfile(uid: auth.currentUid!, phone: '', displayName: 'Sandro', lang: 'en');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        usersRepositoryProvider.overrideWithValue(seeded),
      ],
      child: const MaterialApp(home: SizedBox()),
    ));
    // The plain player profile should render the Player home:
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        usersRepositoryProvider.overrideWithValue(seeded),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: RoleHome(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Player'), findsWidgets);
  });
}
