import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

class PlayerHome extends StatelessWidget {
  const PlayerHome({super.key});
  @override
  Widget build(BuildContext context) => RoleScaffold(title: AppL10n.of(context).playerHome);
}

/// Placeholder role home — replaced by real features in later plans.
class RoleScaffold extends ConsumerWidget {
  const RoleScaffold({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: PsColors.bg0,
      appBar: AppBar(
        backgroundColor: PsColors.bg1,
        title: Text(title, style: const TextStyle(color: PsColors.accentPrimary)),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.signOut, style: TextStyle(color: PsColors.textMuted)),
          ),
        ],
      ),
      body: Center(
        child: Text('$title — coming soon',
            style: const TextStyle(color: PsColors.text, fontSize: PsType.headline)),
      ),
    );
  }
}
