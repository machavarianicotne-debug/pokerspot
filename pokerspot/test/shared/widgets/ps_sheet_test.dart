import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: PsColors.bg0,
        body: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    );

void main() {
  testWidgets('renders the child content', (tester) async {
    await tester.pumpWidget(_wrap(const PsSheet(child: Text('Join waitlist'))));
    expect(find.text('Join waitlist'), findsOneWidget);
  });

  testWidgets('show() presents the sheet over the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => PsSheet.show<void>(context, child: const Text('Picker')),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Picker'), findsOneWidget);
    expect(find.byType(PsSheet), findsOneWidget);
  });

  testWidgets('golden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 390,
          child: PsSheet(
            child: Text(
              'Join the 1/2 NLH waitlist',
              style: TextStyle(fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(PsSheet), matchesGoldenFile('goldens/ps_sheet.png'));
  });
}
