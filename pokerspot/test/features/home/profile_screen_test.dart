import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/profile_screen.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

void main() {
  testWidgets('renders name/phone, account + notification groups, sign-out', (tester) async {
    const user = AppUser(
        uid: 'u', phone: '+995 599 12 34 56', firstName: 'Sandro', lastName: 'Z',
        role: AppRole.player, lang: 'en', blocked: false);
    await tester.pumpWidget(ProviderScope(
      overrides: [currentUserProvider.overrideWith((ref) => Stream.value(user))],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: ProfileScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sandro Z'), findsOneWidget);
    // Phone shows in the header + the Account group row.
    expect(find.text('+995 599 12 34 56'), findsWidgets);
    expect(find.text('English'), findsOneWidget); // language value
    expect(find.text('Seat called'), findsOneWidget); // a notification row
    expect(find.byType(PsToggle), findsNWidgets(3)); // 3 notification toggles
    expect(find.byKey(const Key('signOutBtn')), findsOneWidget);
  });
}
