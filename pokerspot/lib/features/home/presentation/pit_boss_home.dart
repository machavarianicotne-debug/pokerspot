import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/chat_hub_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
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
class PitBossHome extends ConsumerWidget {
  const PitBossHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    final unread = clubId == null
        ? 0
        : (ref.watch(clubThreadsProvider(clubId)).valueOrNull ?? const <ChatThread>[])
            .fold<int>(0, (a, t) => a + t.unread);
    final clubName = clubId == null ? null : ref.watch(clubProvider(clubId)).valueOrNull?.name;
    final title = clubName == null || clubName.isEmpty ? l10n.pitBossHome : clubName;
    return TabShell(
      nav: PsGlassNav(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ClubOrb(letter: title.isEmpty ? '?' : title[0].toUpperCase()),
            const SizedBox(width: PsSpacing.s3),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PsOverline(l10n.tabFloor),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
      items: [
        PsTabItem(Icons.grid_view, l10n.tabFloor),
        PsTabItem(Icons.chat_bubble_outline, l10n.tabInbox, badge: unread),
        PsTabItem(Icons.bar_chart, l10n.tabStats),
        PsTabItem(Icons.settings, l10n.tabSettings),
      ],
      tabs: [
        const TablesScreen(),
        Consumer(builder: (context, ref, _) {
          final user = ref.watch(currentUserProvider).valueOrNull;
          final clubId = user?.clubId ?? '';
          final club = ref.watch(clubProvider(clubId)).valueOrNull ??
              const Club(
                id: '', name: '', city: '', address: '',
                photoUrl: null, hoursText: '', phone: '', enabled: false);
          return PitChatHubScreen(clubId: clubId, clubName: club.name);
        }),
        const PitBossStatsScreen(),
        const PitBossSettingsScreen(),
      ],
    );
  }
}

/// Small gradient club logo orb shown in the Pit Boss nav (mockup club logo).
class _ClubOrb extends StatelessWidget {
  const _ClubOrb({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PsRadii.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PsColors.accentPrimary, PsColors.accentSecondary],
        ),
      ),
      child: Text(letter,
          style: const TextStyle(
              fontSize: 18, fontWeight: PsType.weightBlack, color: PsColors.onAccent)),
    );
  }
}
