import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Align(alignment: Alignment.topCenter, child: child),
      ),
    );

void main() {
  testWidgets('renders the leading brand and the action slots', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PsGlassNav(
          leading: PsBrand('PokerSpot', accent: 'Spot'),
          actions: [PsAvatar(initials: 'SZ')],
        ),
      ),
    );
    expect(find.byType(PsBrand), findsOneWidget);
    expect(find.byType(PsAvatar), findsOneWidget);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 390,
          child: PsGlassNav(
            leading: PsBrand('PokerSpot', accent: 'Spot'),
            actions: [PsAvatar(initials: 'SZ')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsGlassNav), matchesGoldenFile('goldens/ps_glass_nav.png'));
  });
}
