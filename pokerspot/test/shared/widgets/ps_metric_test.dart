import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_metric.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('shows the value and the uppercased label', (tester) async {
    await tester.pumpWidget(_wrap(const PsMetric(value: '12', label: 'Waiting')));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
  });

  testWidgets('hero variant accents the value', (tester) async {
    await tester.pumpWidget(
      _wrap(const PsMetric(value: '03:41', label: 'Elapsed', variant: PsMetricVariant.hero)),
    );
    expect(tester.widget<Text>(find.text('03:41')).style?.color, PsColors.accentPrimary);
  });

  testWidgets('full variant colours the value status-full', (tester) async {
    await tester.pumpWidget(
      _wrap(const PsMetric(value: '9/9', label: 'Seats', variant: PsMetricVariant.full)),
    );
    expect(tester.widget<Text>(find.text('9/9')).style?.color, PsColors.statusFull);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 340,
          child: Row(
            children: [
              Expanded(child: PsMetric(value: '12', label: 'Waiting')),
              SizedBox(width: PsSpacing.s2),
              Expanded(child: PsMetric(value: '03:41', label: 'Elapsed', variant: PsMetricVariant.hero)),
              SizedBox(width: PsSpacing.s2),
              Expanded(child: PsMetric(value: '9/9', label: 'Seats', variant: PsMetricVariant.full)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('goldens/ps_metric.png'));
  });
}
