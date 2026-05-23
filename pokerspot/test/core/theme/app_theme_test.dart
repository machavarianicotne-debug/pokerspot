import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokerspot/core/theme/app_theme.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Prevent GoogleFonts from attempting network requests during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('theme is dark and uses the token background + accent',
      (tester) async {
    final t = AppTheme.liquidSport();
    // pumpWidget flushes the async font-loading microtasks so they resolve
    // inside the test boundary rather than leaking into tearDown.
    await tester.pumpWidget(MaterialApp(theme: t, home: const SizedBox()));
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, PsColors.bg0);
    expect(t.colorScheme.primary, PsColors.accentPrimary);
  });
}
