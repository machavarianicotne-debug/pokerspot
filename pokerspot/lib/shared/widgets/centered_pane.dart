import 'package:flutter/material.dart';

/// Mobile-first responsive wrapper: full-width on narrow screens, a centered
/// 440-px column ("phone frame" feel) on desktop widths.
class CenteredPane extends StatelessWidget {
  const CenteredPane({super.key, required this.child, this.maxWidth = 440});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
