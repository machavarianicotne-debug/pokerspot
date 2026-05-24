import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('paints a custom-painted dot', (tester) async {
    await tester.pumpWidget(_wrap(const PsLiveDot()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PsLiveDot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const PsLiveDot(size: 6)));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(find.byType(PsLiveDot), matchesGoldenFile('goldens/ps_live_dot.png'));
  });
}
