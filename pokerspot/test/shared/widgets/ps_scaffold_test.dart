import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

void main() {
  testWidgets('paints the base gradient + shows the body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PsScaffold(body: Center(child: Text('hi')))),
    );
    expect(find.text('hi'), findsOneWidget);
    final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    expect(
      boxes.any((b) => (b.decoration as BoxDecoration).gradient == PsGradients.backgroundBase),
      isTrue,
    );
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PsScaffold(body: SizedBox.expand())),
    );
    await expectLater(find.byType(PsScaffold), matchesGoldenFile('goldens/ps_scaffold.png'));
  });
}
