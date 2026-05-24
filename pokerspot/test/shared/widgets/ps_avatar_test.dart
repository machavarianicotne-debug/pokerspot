import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('shows the initials over the avatar gradient', (tester) async {
    await tester.pumpWidget(_wrap(const PsAvatar(initials: 'SZ')));
    expect(find.text('SZ'), findsOneWidget);
    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration as BoxDecoration).gradient, PsGradients.avatar);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const PsAvatar(initials: 'SZ', size: 48)));
    await expectLater(find.byType(PsAvatar), matchesGoldenFile('goldens/ps_avatar.png'));
  });
}
