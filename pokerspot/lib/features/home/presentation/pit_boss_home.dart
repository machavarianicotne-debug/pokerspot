import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/chat/presentation/inbox_screen.dart';
import 'package:pokerspot/features/floor/presentation/tables_screen.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_settings_screen.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_stats_screen.dart';
import 'package:pokerspot/features/home/presentation/player_home.dart' show TabShell;
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_tab_bar.dart';

/// Pit Boss home — table-centric (mockup): Floor (the live table cards) / Inbox /
/// Stats / Settings. The per-table waitlist + seated sessions live inside each
/// table's detail (seat map + waitlist section), not a separate tab.
class PitBossHome extends StatelessWidget {
  const PitBossHome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return TabShell(
      nav: PsGlassNav(
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PsOverline(l10n.pitBossHome),
            const SizedBox(height: 2),
            Text(
              l10n.tabFloor,
              style: const TextStyle(
                fontSize: PsType.title,
                fontWeight: PsType.weightBlack,
                letterSpacing: PsType.trackingSnug,
                color: PsColors.text,
              ),
            ),
          ],
        ),
      ),
      items: [
        PsTabItem(Icons.grid_view, l10n.tabFloor),
        PsTabItem(Icons.chat_bubble_outline, l10n.tabInbox),
        PsTabItem(Icons.bar_chart, l10n.tabStats),
        PsTabItem(Icons.settings, l10n.tabSettings),
      ],
      tabs: const [
        TablesScreen(),
        InboxScreen(),
        PitBossStatsScreen(),
        PitBossSettingsScreen(),
      ],
    );
  }
}
