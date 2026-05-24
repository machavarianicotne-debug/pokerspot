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

bool _enabled(WidgetTester t) =>
    t.widget<FilledButton>(find.byKey(const Key('getStartedBtn'))).onPressed != null;

Future<void> _signedIn(FakeAuthRepository auth) async {
  final s = await auth.sendOtp('+995555222222');
  await auth.confirmOtp(s, '222222');
}

void main() {
  testWidgets('both required, min-length enforced per field, distinct names submit',
      (tester) async {
    final auth = FakeAuthRepository();
    final users = FakeUsersRepository();
    await _signedIn(auth);
    await tester.pumpWidget(_wrap(auth, users));

    // pristine: both empty -> disabled
    expect(_enabled(tester), isFalse);

    // first name too short -> inline error + disabled
    await tester.enterText(find.byKey(const Key('firstNameField')), 'a');
    await tester.pump();
    expect(find.text('Min 2 characters'), findsOneWidget);
    expect(_enabled(tester), isFalse);

    // valid first, last too short -> error under last + disabled
    await tester.enterText(find.byKey(const Key('firstNameField')), 'Giorgi');
    await tester.enterText(find.byKey(const Key('lastNameField')), 'b');
    await tester.pump();
    expect(find.text('Min 2 characters'), findsOneWidget);
    expect(_enabled(tester), isFalse);

    // valid + distinct -> enabled, submit creates profile
    await tester.enterText(find.byKey(const Key('lastNameField')), 'Beridze');
    await tester.pump();
    expect(_enabled(tester), isTrue);

    await tester.tap(find.byKey(const Key('getStartedBtn')));
    await tester.pumpAndSettle();

    final created = await users.getUser(auth.currentUid!);
    expect(created?.firstName, 'Giorgi');
    expect(created?.lastName, 'Beridze');
  });

  testWidgets('identical names block submission and show must-differ error', (tester) async {
    final auth = FakeAuthRepository();
    await _signedIn(auth);
    await tester.pumpWidget(_wrap(auth, FakeUsersRepository()));

    await tester.enterText(find.byKey(const Key('firstNameField')), 'Giorgi');
    await tester.enterText(find.byKey(const Key('lastNameField')), 'Giorgi');
    await tester.pump();

    expect(find.text('First and last name must be different'), findsOneWidget);
    expect(_enabled(tester), isFalse);
  });

  testWidgets('case-insensitive match also blocks (john vs JOHN)', (tester) async {
    final auth = FakeAuthRepository();
    await _signedIn(auth);
    await tester.pumpWidget(_wrap(auth, FakeUsersRepository()));

    await tester.enterText(find.byKey(const Key('firstNameField')), 'john');
    await tester.enterText(find.byKey(const Key('lastNameField')), 'JOHN');
    await tester.pump();

    expect(find.text('First and last name must be different'), findsOneWidget);
    expect(_enabled(tester), isFalse);
  });

  testWidgets('desktop width (1280): content is capped by the 440px pane', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(FakeAuthRepository(), FakeUsersRepository()));
    await tester.pumpAndSettle();

    final w = tester.getSize(find.byKey(const Key('firstNameField'))).width;
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

    final w = tester.getSize(find.byKey(const Key('firstNameField'))).width;
    expect(w, lessThan(375));
    expect(w, greaterThan(300));
  });
}
