import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_chat.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

void main() {
  testWidgets('outgoing bubble fills accent-primary; incoming is glass', (tester) async {
    await tester.pumpWidget(_wrap(const Column(
      children: [
        PsChatBubble(text: 'Hi there', outgoing: false, time: '22:40'),
        PsChatBubble(text: 'Hello!', outgoing: true, time: '22:41'),
      ],
    )));
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
    final fills = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration as BoxDecoration?)?.color);
    expect(fills, contains(PsColors.accentPrimary));
  });

  testWidgets('composer send fires', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sent = 0;
    await tester.pumpWidget(_wrap(
      PsComposer(controller: controller, onSend: () => sent++),
    ));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(sent, 1);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(_wrap(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PsChatBubble(text: 'Is there a dress code tonight?', outgoing: true, time: '22:41'),
        SizedBox(height: 8),
        PsChatBubble(text: 'Smart casual — no shorts. You\'re good.', outgoing: false, time: '22:41'),
      ],
    )));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Column).first, matchesGoldenFile('goldens/ps_chat.png'));
  });
}
