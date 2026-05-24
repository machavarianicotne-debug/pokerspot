import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_money_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: child)),
      ),
    );

void main() {
  testWidgets('shows the symbol + hint and reports typed amount', (tester) async {
    String? typed;
    await tester.pumpWidget(_wrap(PsMoneyField(symbol: '₾', hintText: '200', onChanged: (v) => typed = v)));
    expect(find.text('₾'), findsOneWidget);
    expect(find.text('200'), findsOneWidget); // hint

    await tester.enterText(find.byType(TextField), '500');
    expect(typed, '500');
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(width: 280, child: PsMoneyField(symbol: '₾', hintText: '200'))));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsMoneyField), matchesGoldenFile('goldens/ps_money_field.png'));
  });
}
