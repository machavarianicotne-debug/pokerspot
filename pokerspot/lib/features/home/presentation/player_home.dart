import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/presentation/clubs_list_screen.dart';
import 'package:pokerspot/features/home/presentation/activity_screen.dart';
import 'package:pokerspot/features/home/presentation/profile_screen.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
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
    return TabShell(
      nav: PsGlassNav(leading: PsBrand(l10n.appTitle, accent: 'Spot')),
      items: [
        PsTabItem(Icons.casino, l10n.tabClubs),
        PsTabItem(Icons.show_chart, l10n.tabActivity),
        PsTabItem(Icons.person, l10n.tabProfile),
      ],
      tabs: const [ClubsListScreen(), ActivityScreen(), ProfileScreen()],
    );
  }
}

/// Placeholder role home (Super Admin): Overview / Clubs / Profile tabs.
/// Overview + Clubs are stubs that later plans fill in.
class RoleScaffold extends ConsumerWidget {
  const RoleScaffold({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return TabShell(
      nav: PsGlassNav(
        leading: Text(
          title,
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
        PsTabItem(Icons.person, l10n.tabProfile),
      ],
      tabs: [
        // Overview — Plan 6 fills this in.
        StubBody(text: '$title — coming soon'),
        // Clubs management — Plan 6.
        const StubBody(text: 'Coming in Plan 6'),
        const ProfileScreen(),
      ],
    );
  }
}

/// A centered placeholder body for not-yet-built tabs.
class StubBody extends StatelessWidget {
  const StubBody({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PsSpacing.s5),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PsColors.text, fontSize: PsType.headline),
        ),
      ),
    );
  }
}
