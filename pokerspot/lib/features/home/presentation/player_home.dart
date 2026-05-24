import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/presentation/clubs_list_screen.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/activity_screen.dart';
import 'package:pokerspot/features/home/presentation/profile_screen.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_tab_bar.dart';

/// Wraps a nav + tabbed body: [nav] on top, [tabs] in an IndexedStack (state
/// preserved across switches), and a floating [PsTabBar] over the bottom.
/// Shared by all three role homes.
class TabShell extends StatefulWidget {
  const TabShell({super.key, required this.nav, required this.items, required this.tabs});

  final Widget nav;
  final List<PsTabItem> items;
  final List<Widget> tabs;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return PsScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                widget.nav,
                Expanded(child: IndexedStack(index: _tab, children: widget.tabs)),
              ],
            ),
            Positioned(
              left: PsSpacing.s4,
              right: PsSpacing.s4,
              bottom: 12,
              child: PsTabBar(
                items: widget.items,
                currentIndex: _tab,
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Player home: Clubs / Activity / Profile tabs under the brand nav.
class PlayerHome extends ConsumerWidget {
  const PlayerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final liveCount = (ref.watch(clubsListProvider).valueOrNull ?? const [])
        .where((c) => c.live)
        .length;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final initials = _initials(user == null ? '' : '${user.firstName} ${user.lastName}');
    return TabShell(
      nav: PsGlassNav(
        leading: PsBrand(l10n.appTitle, accent: 'Spot'),
        actions: [
          _LiveCountPill(count: liveCount, label: l10n.liveCountLabel),
          PsAvatar(initials: initials),
        ],
      ),
      items: [
        PsTabItem(Icons.casino, l10n.tabClubs),
        PsTabItem(Icons.show_chart, l10n.tabActivity),
        PsTabItem(Icons.person, l10n.tabProfile),
      ],
      tabs: const [ClubsListScreen(), ActivityScreen(), ProfileScreen()],
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.length == 1
            ? (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
            : parts.first[0] + parts.last[0])
        .toUpperCase();
  }
}

/// The "N LIVE" nav pill (mockup `.livecount`): glass pill + pulsing live dot.
class _LiveCountPill extends StatelessWidget {
  const _LiveCountPill({required this.count, required this.label});
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: PsColors.glassRegular,
        borderRadius: BorderRadius.circular(PsRadii.full),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PsLiveDot(),
          const SizedBox(width: 6),
          Text('$count $label',
              style: const TextStyle(
                  fontSize: PsType.caption,
                  fontWeight: PsType.weightBlack,
                  letterSpacing: PsType.trackingWide,
                  color: PsColors.text)),
        ],
      ),
    );
  }
}

