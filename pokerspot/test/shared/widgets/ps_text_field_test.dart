import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: child)),
      ),
    );

BoxDecoration _decoration(WidgetTester tester) => tester
        .widget<AnimatedContainer>(
          find.descendant(of: find.byType(PsTextField), matching: find.byType(AnimatedContainer)),
        )
        .decoration! as BoxDecoration;

void main() {
  testWidgets('shows the hint and reports typed text', (tester) async {
    String? typed;
    await tester.pumpWidget(_wrap(PsTextField(hintText: 'Phone', onChanged: (v) => typed = v)));
    expect(find.text('Phone'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '555');
    expect(typed, '555');
  });

  testWidgets('focus turns the border accent-secondary with a glow', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(_wrap(PsTextField(focusNode: node, hintText: 'Phone')));

    expect((_decoration(tester).border! as Border).top.color, PsColors.glassBorder);

    node.requestFocus();
    await tester.pump();
    await tester.pump(PsMotion.fast);

    final dec = _decoration(tester);
    expect((dec.border! as Border).top.color, PsColors.accentSecondary);
    expect(dec.boxShadow, isNotNull);
  });

  testWidgets('errorText turns the border status-full and shows the message', (tester) async {
    await tester.pumpWidget(_wrap(const PsTextField(hintText: 'Name', errorText: 'Too short')));
    expect(find.text('Too short'), findsOneWidget);
    expect((_decoration(tester).border! as Border).top.color, PsColors.statusFull);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PsTextField(hintText: 'Phone number', prefixText: '+995 '),
            SizedBox(height: PsSpacing.s4),
            PsTextField(hintText: 'Last name', errorText: 'Too short'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/ps_text_field.png'));
  });
}
