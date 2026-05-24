import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokerspot/app/app.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/presentation/login_screen.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app launches and a signed-out user lands on the login screen', (tester) async {
    // Override the Firebase-backed repos with fakes: the real providers call
    // FirebaseAuth.instance / FirebaseFirestore.instance, which throw without a
    // live Firebase app in a unit test.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        usersRepositoryProvider.overrideWithValue(FakeUsersRepository()),
      ],
      child: const PokerSpotApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
