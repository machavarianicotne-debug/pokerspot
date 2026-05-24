import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    );

void main() {
  testWidgets('shows leading, title, subtitle and trailing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PsListTile(
          leading: PsAvatar(initials: 'VA'),
          title: 'PokerSpot Vake',
          subtitle: 'Tbilisi · Chavchavadze 47',
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
    expect(find.text('PokerSpot Vake'), findsOneWidget);
    expect(find.text('Tbilisi · Chavchavadze 47'), findsOneWidget);
    expect(find.byType(PsAvatar), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PsCard(
          child: PsListTile(
            leading: const PsAvatar(initials: 'VA'),
            title: 'PokerSpot Vake',
            subtitle: 'Tbilisi · Chavchavadze 47',
            trailing: Icon(Icons.chevron_right, color: PsColors.textFaint),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsCard), matchesGoldenFile('goldens/ps_list_tile.png'));
  });
}
