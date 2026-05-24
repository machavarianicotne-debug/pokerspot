import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

void main() {
  testWidgets('renders child and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PsCard(onTap: () => taps++, child: const Text('Card body'))),
    );
    expect(find.text('Card body'), findsOneWidget);

    await tester.tap(find.byType(PsCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('paints the accent rail in the given colour', (tester) async {
    await tester.pumpWidget(
      _wrap(const PsCard(accentRail: PsColors.statusFull, child: Text('x'))),
    );
    final rails = tester.widgetList<Container>(find.byType(Container)).map((c) => c.color);
    expect(rails, contains(PsColors.statusFull));
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PsCard(
          accentRail: PsColors.accentPrimary,
          child: Text(
            'PokerSpot Vake',
            style: TextStyle(fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsCard), matchesGoldenFile('goldens/ps_card.png'));
  });
}
