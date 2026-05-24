import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// One entry in a [PsTabBar].
class PsTabItem {
  const PsTabItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Liquid Sport tab bar (`.ps-tabbar`): a floating glass-thick bar with a top
/// highlight + elevation-4 shadow. Each tab is an icon over a micro uppercase
/// label; the active tab turns accent-primary. The screen positions it (e.g.
/// in a Stack, inset from the edges). vs Material BottomNavigationBar: floating
/// glass pill, no Material fill/ink.
class PsTabBar extends StatelessWidget {
  const PsTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PsTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(PsRadii.xl);

    final bar = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: PsGlass.backdrop(PsGlass.blurThick),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PsColors.glassRegular,
            borderRadius: radius,
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 11, 8, 9),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++) _tab(i),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(gradient: PsGradients.glassHighlightLine),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: PsElevation.e4),
        child: bar,
      ),
    );
  }

  Widget _tab(int i) {
    final active = i == currentIndex;
    final color = active ? PsColors.accentPrimary : PsColors.textFaint;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(items[i].icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              items[i].label.toUpperCase(),
              style: TextStyle(
                fontSize: PsType.micro,
                fontWeight: PsType.weightBlack,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
