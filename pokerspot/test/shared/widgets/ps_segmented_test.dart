import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_segmented.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: child)),
      ),
    );

void main() {
  testWidgets('renders segments; tapping one reports its value', (tester) async {
    String? picked;
    await tester.pumpWidget(_wrap(PsSegmented<String>(
      value: 'nlh',
      segments: const [PsSegment('nlh', 'NLH'), PsSegment('plo', 'PLO'), PsSegment('plo5', 'PLO5')],
      onChanged: (v) => picked = v,
    )));
    expect(find.text('NLH'), findsOneWidget);
    expect(find.text('PLO5'), findsOneWidget);

    await tester.tap(find.text('PLO'));
    await tester.pump();
    expect(picked, 'plo');
  });

  testWidgets('selected segment fills with accent-primary', (tester) async {
    await tester.pumpWidget(_wrap(PsSegmented<String>(
      value: 'plo',
      segments: const [PsSegment('nlh', 'NLH'), PsSegment('plo', 'PLO')],
      onChanged: (_) {},
    )));
    final fills = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration as BoxDecoration?)?.color);
    expect(fills, contains(PsColors.accentPrimary));
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(SizedBox(
      width: 280,
      child: PsSegmented<int>(
        value: 1,
        segments: const [PsSegment(0, 'NLH'), PsSegment(1, 'PLO'), PsSegment(2, 'PLO5'), PsSegment(3, 'PLO6')],
        onChanged: (_) {},
      ),
    )));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsSegmented<int>), matchesGoldenFile('goldens/ps_segmented.png'));
  });
}
