import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/onboarding/presentation/onboarding_screen.dart';

Widget _wrap(FakeAuthRepository auth, FakeUsersRepository users) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        usersRepositoryProvider.overrideWithValue(users),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: OnboardingScreen(),
      ),
    );

void main() {
  testWidgets('Get Started disabled until name; then creates profile', (tester) async {
    final auth = FakeAuthRepository();
    final users = FakeUsersRepository();
    final s = await auth.sendOtp('+995555222222');
    await auth.confirmOtp(s, '222222');

    await tester.pumpWidget(_wrap(auth, users));

    final btn = find.byKey(const Key('getStartedBtn'));
    expect(tester.widget<FilledButton>(btn).onPressed, isNull); // disabled

    await tester.enterText(find.byKey(const Key('nameField')), 'Nino');
    await tester.pump();
    expect(tester.widget<FilledButton>(btn).onPressed, isNotNull); // enabled

    await tester.tap(btn);
    await tester.pumpAndSettle();

    final created = await users.getUser(auth.currentUid!);
    expect(created?.displayName, 'Nino');
  });

  testWidgets('desktop width (1280): content is capped by the 440px pane', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(FakeAuthRepository(), FakeUsersRepository()));
    await tester.pumpAndSettle();

    final w = tester.getSize(find.byKey(const Key('nameField'))).width;
    expect(w, lessThanOrEqualTo(440));
    expect(w, greaterThan(300));
  });

  testWidgets('mobile width (375): content is (near) full-width', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(FakeAuthRepository(), FakeUsersRepository()));
    await tester.pumpAndSettle();

    final w = tester.getSize(find.byKey(const Key('nameField'))).width;
    expect(w, lessThan(375));
    expect(w, greaterThan(300));
  });
}
