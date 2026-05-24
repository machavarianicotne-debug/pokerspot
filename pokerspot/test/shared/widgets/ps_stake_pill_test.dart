import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_stake_pill.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('shows the accent type next to the stake value', (tester) async {
    await tester.pumpWidget(_wrap(const PsStakePill(type: 'NLH', value: '1/2 GEL')));
    expect(find.text('NLH'), findsOneWidget);
    expect(find.text('1/2 GEL'), findsOneWidget);

    final type = tester.widget<Text>(find.text('NLH'));
    expect(type.style?.color, PsColors.accentPrimary);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const PsStakePill(type: 'PLO', value: '2/5 GEL')));
    await expectLater(find.byType(PsStakePill), matchesGoldenFile('goldens/ps_stake_pill.png'));
  });
}
