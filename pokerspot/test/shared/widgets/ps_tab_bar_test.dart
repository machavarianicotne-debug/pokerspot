import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_tab_bar.dart';

const _items = [
  PsTabItem(Icons.casino, 'Clubs'),
  PsTabItem(Icons.event_seat, 'Status'),
  PsTabItem(Icons.person, 'Profile'),
];

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    );

void main() {
  testWidgets('renders uppercased labels and tapping fires the index', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _wrap(PsTabBar(items: _items, currentIndex: 0, onTap: (i) => tapped = i)),
    );
    expect(find.text('CLUBS'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);

    await tester.tap(find.text('STATUS'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('active tab is accent, others are faint', (tester) async {
    await tester.pumpWidget(
      _wrap(PsTabBar(items: _items, currentIndex: 0, onTap: (_) {})),
    );
    expect(tester.widget<Text>(find.text('CLUBS')).style?.color, PsColors.accentPrimary);
    expect(tester.widget<Text>(find.text('STATUS')).style?.color, PsColors.textFaint);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 360,
          child: PsTabBar(items: _items, currentIndex: 0, onTap: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsTabBar), matchesGoldenFile('goldens/ps_tab_bar.png'));
  });
}
