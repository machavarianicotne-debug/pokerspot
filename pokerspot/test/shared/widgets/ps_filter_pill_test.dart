import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('inactive pill is glass; tapping fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PsFilterPill(label: 'Tbilisi', onTap: () => taps++)));

    expect(find.text('Tbilisi'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tap(find.byType(PsFilterPill));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('active pill fills with accent-primary and drops the glass', (tester) async {
    await tester.pumpWidget(_wrap(const PsFilterPill(label: 'All', active: true)));
    expect(find.byType(BackdropFilter), findsNothing);

    final fills = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => (b.decoration as BoxDecoration).color);
    expect(fills, contains(PsColors.accentPrimary));
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PsFilterPill(label: 'All', active: true),
            SizedBox(width: PsSpacing.s2),
            PsFilterPill(label: 'Tbilisi'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('goldens/ps_filter_pill.png'));
  });
}
