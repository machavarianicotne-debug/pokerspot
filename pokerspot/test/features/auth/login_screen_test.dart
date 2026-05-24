import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/login_screen.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

Widget _wrap(Widget child, FakeAuthRepository auth) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('enter phone → send → enter code → sign in', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(const LoginScreen(), auth));

    await tester.enterText(find.byKey(const Key('phoneField')), '+995555111111');
    await tester.tap(find.byKey(const Key('sendCodeBtn')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('codeField')), '111111');
    await tester.tap(find.byKey(const Key('verifyBtn')));
    await tester.pumpAndSettle();

    expect(auth.currentUid, isNotNull);
  });

  testWidgets('invalid phone shows error, does not send', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(const LoginScreen(), auth));
    await tester.enterText(find.byKey(const Key('phoneField')), '123');
    await tester.tap(find.byKey(const Key('sendCodeBtn')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid +995 number'), findsOneWidget);
  });

  testWidgets('desktop width (1280): content is capped by the 440px pane', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(const LoginScreen(), auth));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phoneField')), findsOneWidget);
    final fieldWidth = tester.getSize(find.byKey(const Key('phoneField'))).width;
    expect(fieldWidth, lessThanOrEqualTo(440));
    expect(fieldWidth, greaterThan(300));
  });

  testWidgets('mobile width (375): content is (near) full-width', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(const LoginScreen(), auth));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phoneField')), findsOneWidget);
    final fieldWidth = tester.getSize(find.byKey(const Key('phoneField'))).width;
    // Narrower than the viewport (padding) but wider than the 440 cap minus padding.
    expect(fieldWidth, lessThan(375));
    expect(fieldWidth, greaterThan(300));
  });
}
