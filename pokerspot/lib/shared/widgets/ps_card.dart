import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport card (`.ps-card`): a glass surface (blur-regular + saturate)
/// with a 1px top highlight, elevation-4 shadow and an optional 4px left
/// [accentRail] (state colour). Springs to `scale(0.985)` when [onTap] is set.
/// vs Material Card: glass not solid; accent rail; spring press.
class PsCard extends StatefulWidget {
  const PsCard({
    super.key,
    required this.child,
    this.accentRail,
    this.onTap,
    this.padding = const EdgeInsets.all(PsSpacing.s4),
  });

  final Widget child;
  final Color? accentRail;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<PsCard> createState() => _PsCardState();
}

class _PsCardState extends State<PsCard> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap != null && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(PsRadii.lg);

    final surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter.grouped(
        filter: PsGlass.backdrop(PsGlass.blurRegular),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PsColors.glassThin,
            borderRadius: radius,
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Stack(
            children: [
              Padding(padding: widget.padding, child: widget.child),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 1, color: PsColors.glassHighlight),
              ),
              if (widget.accentRail != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: widget.accentRail),
                ),
            ],
          ),
        ),
      ),
    );

    final card = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: PsElevation.e4),
        child: surface,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: PsMotion.normal,
        curve: PsMotion.ease,
        child: card,
      ),
    );
  }
}
