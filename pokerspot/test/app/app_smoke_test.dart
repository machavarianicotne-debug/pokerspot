import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokerspot/app/app.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app launches and shows the themed home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokerSpotApp()));
    await tester.pumpAndSettle();

    expect(find.text('PokerSpot'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, PsColors.bg0);
  });
}
