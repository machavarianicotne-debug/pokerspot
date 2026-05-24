import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(backgroundColor: PsColors.bg0, body: Center(child: child)),
    );

void main() {
  testWidgets('shows mm:ss for a future deadline, then expired', (tester) async {
    await tester.pumpWidget(_wrap(
      PsCountdown(deadline: DateTime.now().add(const Duration(seconds: 90))),
    ));
    await tester.pump();
    expect(find.textContaining(':'), findsOneWidget); // e.g. 1:29

    // A past deadline shows the expired label.
    await tester.pumpWidget(_wrap(
      PsCountdown(deadline: DateTime.now().subtract(const Duration(seconds: 1))),
    ));
    await tester.pump();
    expect(find.text('expired'), findsOneWidget);

    // Dispose the live timer to avoid a pending-timer failure.
    await tester.pumpWidget(const SizedBox());
  });
}
