import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

BoxDecoration _trackDecoration(WidgetTester tester) => tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer))
        .decoration! as BoxDecoration;

void main() {
  testWidgets('off track is glass; tapping requests the on value', (tester) async {
    bool? next;
    await tester.pumpWidget(_wrap(PsToggle(value: false, onChanged: (v) => next = v)));
    expect(_trackDecoration(tester).color, PsColors.glassRegular);

    await tester.tap(find.byType(PsToggle));
    await tester.pump();
    expect(next, true);
  });

  testWidgets('on track turns accent-secondary', (tester) async {
    await tester.pumpWidget(_wrap(PsToggle(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(_trackDecoration(tester).color, PsColors.accentSecondary);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PsToggle(value: false, onChanged: (_) {}, label: 'OFF'),
            const SizedBox(height: PsSpacing.s3),
            PsToggle(value: true, onChanged: (_) {}, label: 'NLH ONLY'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/ps_toggle.png'));
  });
}
