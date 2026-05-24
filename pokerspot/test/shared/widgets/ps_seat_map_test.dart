import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

void main() {
  testWidgets('shows open/total and an OPEN label when seats are free', (tester) async {
    await tester.pumpWidget(_wrap(
      const PsSeatMap(seatCount: 9, filledSeats: {1, 2, 3, 4, 5, 6, 7}),
    ));
    expect(find.text('2/9'), findsOneWidget); // 9 - 7 = 2 open
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('full table shows FULL', (tester) async {
    await tester.pumpWidget(_wrap(
      const PsSeatMap(seatCount: 6, filledSeats: {1, 2, 3, 4, 5, 6}),
    ));
    expect(find.text('FULL'), findsOneWidget);
    expect(find.text('6/6'), findsOneWidget);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(
      const PsSeatMap(seatCount: 9, filledSeats: {1, 2, 3, 4, 5, 6, 7}, warnSeats: {7}),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsSeatMap), matchesGoldenFile('goldens/ps_seat_map.png'));
  });
}
