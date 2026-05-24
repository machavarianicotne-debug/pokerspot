import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_bar_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: child)),
      ),
    );

void main() {
  testWidgets('renders a labelled bar per entry', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(
      width: 280,
      child: PsBarChart(bars: [
        PsBar(48, 'M'), PsBar(60, 'T'), PsBar(42, 'W'), PsBar(70, 'T'),
        PsBar(88, 'F'), PsBar(100, 'S'), PsBar(64, 'S'),
      ]),
    )));
    expect(find.text('M'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.textContaining('S'), findsWidgets);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(
      width: 280,
      child: PsBarChart(bars: [
        PsBar(48, 'M'), PsBar(60, 'T'), PsBar(42, 'W'), PsBar(70, 'T'),
        PsBar(88, 'F'), PsBar(100, 'S'), PsBar(64, 'S'),
      ]),
    )));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsBarChart), matchesGoldenFile('goldens/ps_bar_chart.png'));
  });
}
