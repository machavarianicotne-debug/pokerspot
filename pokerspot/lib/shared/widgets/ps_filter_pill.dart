import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport filter pill (`.ps-filter-pill`): a tappable rounded chip. The
/// inactive state is glass (blur-thin) with a muted label; the active state
/// fills with accent-primary. Presses spring to `scale(0.96)`.
class PsFilterPill extends StatefulWidget {
  const PsFilterPill({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  State<PsFilterPill> createState() => _PsFilterPillState();
}

class _PsFilterPillState extends State<PsFilterPill> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap != null && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.active ? PsColors.onAccent : PsColors.text;
    final radius = BorderRadius.circular(PsRadii.full);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: PsType.subhead, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: PsType.subhead,
              fontWeight: PsType.weightBold,
              color: fg,
            ),
          ),
        ],
      ),
    );

    Widget pill;
    if (widget.active) {
      pill = DecoratedBox(
        decoration: BoxDecoration(color: PsColors.accentPrimary, borderRadius: radius),
        child: content,
      );
    } else {
      pill = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: PsGlass.backdrop(PsGlass.blurThin),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PsColors.glassThin,
              borderRadius: radius,
              border: Border.all(color: PsColors.glassBorder),
            ),
            child: content,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: PsMotion.fast,
        curve: PsMotion.ease,
        child: pill,
      ),
    );
  }
}
