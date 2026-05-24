import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

void main() {
  testWidgets('renders uppercased with the overline token style', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PsOverline('live tables'))),
    );
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.data, 'LIVE TABLES');
    expect(t.style!.fontSize, PsType.micro);
    expect(t.style!.fontWeight, PsType.weightBlack);
    expect(t.style!.letterSpacing, PsType.trackingOverline);
    expect(t.style!.color, PsColors.textFaint);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: PsColors.bg0,
          body: Center(child: PsOverline('live tables')),
        ),
      ),
    );
    await expectLater(
      find.byType(PsOverline),
      matchesGoldenFile('goldens/ps_overline.png'),
    );
  });
}
