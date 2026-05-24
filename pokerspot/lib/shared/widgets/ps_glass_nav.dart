import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport top bar (`.ps-glass-nav`): a transparent padded row that floats
/// over the scaffold's blurred background — a [leading] slot (usually a
/// [PsBrand] or screen title) at the start and [actions] at the end. vs
/// Material AppBar: no elevation line, no ink, no opaque fill.
class PsGlassNav extends StatelessWidget {
  const PsGlassNav({super.key, required this.leading, this.actions = const []});

  final Widget leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s5, PsSpacing.s2, PsSpacing.s5, PsSpacing.s3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: leading),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: PsSpacing.s2),
                  actions[i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}
