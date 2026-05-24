import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: child)),
      ),
    );

void main() {
  testWidgets('renders rows; tappable row fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PsSettingsGroup(children: [
      PsSettingsRow(label: 'Display name', value: 'Sandro Z.', onTap: () => taps++),
      const PsSettingsRow(label: 'Phone', value: '+995 599 12 34 56'),
    ])));
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('+995 599 12 34 56'), findsOneWidget);

    await tester.tap(find.text('Display name'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PsSettingsGroup.header('Account'),
          PsSettingsGroup(children: [
            PsSettingsRow(label: 'Display name', value: 'Sandro Z.', onTap: () {}),
            const PsSettingsRow(label: 'Phone', value: '+995 599 12 34 56'),
            const PsSettingsRow(label: 'Language', value: 'EN'),
          ]),
        ],
      ),
    )));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/ps_settings_group.png'));
  });
}
