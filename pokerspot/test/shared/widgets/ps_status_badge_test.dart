import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';
import 'package:pokerspot/shared/widgets/ps_status_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

Color _badgeColor(WidgetTester tester) =>
    (tester.widget<Container>(find.byType(Container)).decoration! as BoxDecoration).color!;

void main() {
  testWidgets('live badge is solid red with a pulse dot and uppercased label', (tester) async {
    await tester.pumpWidget(_wrap(const PsStatusBadge(status: PsStatus.live, label: 'Live')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byType(PsLiveDot), findsOneWidget);
    expect(_badgeColor(tester), PsColors.statusLive);
  });

  testWidgets('closed badge is muted glass with no pulse dot', (tester) async {
    await tester.pumpWidget(_wrap(const PsStatusBadge(status: PsStatus.closed, label: 'Closed')));
    expect(find.byType(PsLiveDot), findsNothing);
    expect(_badgeColor(tester), PsColors.glassThin);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PsStatusBadge(status: PsStatus.live, label: 'Live'),
            SizedBox(width: PsSpacing.s2),
            PsStatusBadge(status: PsStatus.open, label: 'Open'),
            SizedBox(width: PsSpacing.s2),
            PsStatusBadge(status: PsStatus.closed, label: 'Closed'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(Row).first, matchesGoldenFile('goldens/ps_status_badge.png'));
  });
}
