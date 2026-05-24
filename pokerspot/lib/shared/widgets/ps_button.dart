import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

enum PsButtonVariant { primary, secondary, ghost }

/// Liquid Sport button (`.ps-btn`): 50px min-height, radius-md, headline/bold/
/// snug label, `scale(0.98)` spring on press. primary = accent fill; secondary
/// = glass (blur-thin); ghost = transparent, accent label. vs FilledButton: no
/// ripple/Material state, lime fill, glass secondary, spring press.
class PsButton extends StatefulWidget {
  const PsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PsButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PsButtonVariant variant;
  final IconData? icon;

  @override
  State<PsButton> createState() => _PsButtonState();
}

class _PsButtonState extends State<PsButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _pressed != v) setState(() => _pressed = v);
  }

  Color get _fg {
    switch (widget.variant) {
      case PsButtonVariant.primary:
        return PsColors.onAccent;
      case PsButtonVariant.secondary:
        return PsColors.text;
      case PsButtonVariant.ghost:
        return PsColors.accentPrimary;
    }
  }

  BoxDecoration? _decoration(BorderRadius radius) {
    switch (widget.variant) {
      case PsButtonVariant.primary:
        return BoxDecoration(color: PsColors.accentPrimary, borderRadius: radius);
      case PsButtonVariant.secondary:
        return BoxDecoration(
          color: PsColors.glassRegular,
          borderRadius: radius,
          border: Border.all(color: PsColors.glassBorder),
        );
      case PsButtonVariant.ghost:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(PsRadii.md);

    // Centred + 50px min-height. Fills the width when the parent constrains it
    // tightly (stretch column) and shrinks to content otherwise (inline in a row).
    final inner = Container(
      constraints: const BoxConstraints(minHeight: 50),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s5),
      decoration: _decoration(radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: PsType.headline, color: _fg),
            const SizedBox(width: PsSpacing.s2),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: PsType.headline,
              fontWeight: PsType.weightBold,
              letterSpacing: PsType.trackingSnug,
              color: _fg,
            ),
          ),
        ],
      ),
    );

    final box = widget.variant == PsButtonVariant.secondary
        ? ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(filter: PsGlass.backdrop(PsGlass.blurThin), child: inner),
          )
        : inner;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: PsMotion.fast,
          curve: PsMotion.ease,
          child: Opacity(opacity: _enabled ? 1.0 : 0.5, child: box),
        ),
      ),
    );
  }
}
