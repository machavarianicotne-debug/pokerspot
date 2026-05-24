import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Center(child: SizedBox(width: 240, child: child)),
      ),
    );

void main() {
  testWidgets('primary fires onPressed and paints the accent fill', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PsButton(label: 'Send code', onPressed: () => taps++)));

    expect(find.text('Send code'), findsOneWidget);
    final fill = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).map(
          (b) => (b.decoration as BoxDecoration).color,
        );
    expect(fill, contains(PsColors.accentPrimary));

    await tester.tap(find.byType(PsButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('disabled (onPressed null) dims to 0.5 and ignores taps', (tester) async {
    await tester.pumpWidget(_wrap(const PsButton(label: 'Send code')));

    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(PsButton), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.5);

    await tester.tap(find.byType(PsButton));
    await tester.pump();
    // No callback, no throw — simply nothing happens.
  });

  testWidgets('secondary uses a glass backdrop', (tester) async {
    await tester.pumpWidget(
      _wrap(PsButton(label: 'Cancel', variant: PsButtonVariant.secondary, onPressed: () {})),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('ghost has no fill and an accent label', (tester) async {
    await tester.pumpWidget(
      _wrap(PsButton(label: 'Skip', variant: PsButtonVariant.ghost, onPressed: () {})),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final label = tester.widget<Text>(find.text('Skip'));
    expect(label.style?.color, PsColors.accentPrimary);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: PsColors.bg0,
          body: Center(
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PsButton(label: 'Send code', onPressed: () {}),
                  const SizedBox(height: PsSpacing.s3),
                  PsButton(label: 'Cancel', variant: PsButtonVariant.secondary, onPressed: () {}),
                  const SizedBox(height: PsSpacing.s3),
                  PsButton(label: 'Skip', variant: PsButtonVariant.ghost, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/ps_button.png'),
    );
  });
}
