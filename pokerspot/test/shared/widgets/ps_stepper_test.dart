import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_stepper.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('increments and decrements within bounds', (tester) async {
    var v = 2;
    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) => PsStepper(
        value: v,
        min: 1,
        max: 3,
        unit: 'table(s)',
        onChanged: (n) => setState(() => v = n),
      ),
    )));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('table(s)'), findsOneWidget);

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(v, 3);

    // at max: + is disabled (no change)
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(v, 3);

    await tester.tap(find.text('−'));
    await tester.pump();
    expect(v, 2);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(PsStepper(value: 2, unit: 'table(s)', onChanged: (_) {})));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsStepper), matchesGoldenFile('goldens/ps_stepper.png'));
  });
}
