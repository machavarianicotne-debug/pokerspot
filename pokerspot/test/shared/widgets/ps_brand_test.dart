import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';

void main() {
  testWidgets('whole word: accent-primary, italic, black, tight tracking', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PsBrand('PokerSpot'))));
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.data, 'PokerSpot');
    expect(t.style!.fontStyle, FontStyle.italic);
    expect(t.style!.fontWeight, PsType.weightBlack);
    expect(t.style!.letterSpacing, PsType.trackingTight);
    expect(t.style!.color, PsColors.accentPrimary);
  });

  testWidgets('accent substring is colored accent-primary, rest uses base color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PsBrand('PokerSpot', accent: 'Spot'))),
    );
    final t = tester.widget<Text>(find.byType(Text));
    final root = t.textSpan! as TextSpan;
    final children = root.children!.cast<TextSpan>();
    expect(children.any((c) => c.text == 'Spot' && c.style?.color == PsColors.accentPrimary), isTrue);
    expect(children.any((c) => c.text == 'Poker'), isTrue);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: PsColors.bg0,
          body: Center(child: PsBrand('PokerSpot', accent: 'Spot', fontSize: PsType.display1)),
        ),
      ),
    );
    await expectLater(find.byType(PsBrand), matchesGoldenFile('goldens/ps_brand.png'));
  });
}
