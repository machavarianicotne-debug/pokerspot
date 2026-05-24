import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_fab.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('renders label + icon and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PsFab(label: 'New Club', icon: Icons.add, onPressed: () => taps++)));
    expect(find.text('New Club'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byType(PsFab));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(PsFab(label: 'New Club', icon: Icons.add, onPressed: () {})));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsFab), matchesGoldenFile('goldens/ps_fab.png'));
  });
}
