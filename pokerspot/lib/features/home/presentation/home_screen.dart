import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: PsColors.bg0,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.appTitle,
              style: const TextStyle(
                color: PsColors.accentPrimary,
                fontSize: PsType.display1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: PsSpacing.s3),
            Text('Foundation ready',
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          ],
        ),
      ),
    );
  }
}
