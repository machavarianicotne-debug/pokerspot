import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/presentation/clubs_list_screen.dart';
import 'package:pokerspot/features/floor/presentation/my_waitlist_banner.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// A round glass sign-out affordance for the nav action slot.
class _SignOutAction extends ConsumerWidget {
  const _SignOutAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return Semantics(
      button: true,
      label: l10n.signOut,
      child: GestureDetector(
        onTap: () => ref.read(authRepositoryProvider).signOut(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s1),
          child: Icon(Icons.logout, size: 22, color: PsColors.textMuted),
        ),
      ),
    );
  }
}

/// Player home: the brand nav, the player's waitlist banner, and the clubs list.
class PlayerHome extends ConsumerWidget {
  const PlayerHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            PsGlassNav(
              leading: PsBrand(l10n.appTitle, accent: 'Spot'),
              actions: const [_SignOutAction()],
            ),
            const MyWaitlistBanner(),
            const Expanded(child: ClubsListScreen()),
          ],
        ),
      ),
    );
  }
}

/// Placeholder role home — replaced by real features in later plans.
class RoleScaffold extends ConsumerWidget {
  const RoleScaffold({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            PsGlassNav(
              leading: Text(
                title,
                style: const TextStyle(
                  fontSize: PsType.title,
                  fontWeight: PsType.weightBlack,
                  color: PsColors.accentPrimary,
                ),
              ),
              actions: const [_SignOutAction()],
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$title — coming soon',
                  style: const TextStyle(color: PsColors.text, fontSize: PsType.headline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
