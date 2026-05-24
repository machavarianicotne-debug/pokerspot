import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport floating action button (mockup `.fab`): an accent-primary pill
/// with an icon + label, elevation-4 plus an accent glow. The screen positions
/// it (e.g. in a Stack). vs Material FAB: pill + label, accent glow, no ink.
class PsFab extends StatefulWidget {
  const PsFab({super.key, required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<PsFab> createState() => _PsFabState();
}

class _PsFabState extends State<PsFab> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onPressed != null && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: PsMotion.fast,
        curve: PsMotion.ease,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PsColors.accentPrimary,
            borderRadius: BorderRadius.circular(PsRadii.full),
            boxShadow: [
              ...PsElevation.e4,
              const BoxShadow(color: PsColors.accentPrimary, blurRadius: 30, spreadRadius: -8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: PsColors.onAccent),
              const SizedBox(width: PsSpacing.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: PsType.body,
                  fontWeight: PsType.weightBlack,
                  color: PsColors.onAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
