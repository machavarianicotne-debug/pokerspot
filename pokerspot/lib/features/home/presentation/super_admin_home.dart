import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/presentation/admin_assign_pitboss_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_clubs_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_overview_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_users_screen.dart';
import 'package:pokerspot/features/home/presentation/player_home.dart' show TabShell;
import 'package:pokerspot/features/home/presentation/profile_screen.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
import 'package:pokerspot/shared/widgets/ps_tab_bar.dart';

/// Super Admin home: Overview / Clubs / Users / Profile tabs.
class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return TabShell(
      nav: PsGlassNav(
        leading: Text(
          l10n.superAdminHome,
          style: const TextStyle(
            fontSize: PsType.title,
            fontWeight: PsType.weightBlack,
            letterSpacing: PsType.trackingSnug,
            color: PsColors.accentPrimary,
          ),
        ),
      ),
      items: [
        PsTabItem(Icons.dashboard, l10n.tabOverview),
        PsTabItem(Icons.casino, l10n.tabClubs),
        PsTabItem(Icons.badge, l10n.tabPitBosses),
        PsTabItem(Icons.group, l10n.tabUsers),
        PsTabItem(Icons.settings, l10n.tabSettings),
      ],
      tabs: const [
        AdminOverviewScreen(),
        AdminClubsScreen(),
        AdminAssignPitBossScreen(),
        AdminUsersScreen(),
        ProfileScreen(),
      ],
    );
  }
}
