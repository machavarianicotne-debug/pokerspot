import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport live indicator (`.ps-live-dot`): a small solid dot with an
/// expanding, fading pulse ring (CSS `@keyframes ps-pulse`, 1.6s infinite). The
/// ring overflows the layout box so the dot still occupies only [size] px.
class PsLiveDot extends StatefulWidget {
  const PsLiveDot({super.key, this.color = PsColors.statusLive, this.size = 6});

  final Color color;
  final double size;

  @override
  State<PsLiveDot> createState() => _PsLiveDotState();
}

class _PsLiveDotState extends State<PsLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: OverflowBox(
          maxWidth: widget.size + 16,
          maxHeight: widget.size + 16,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size + 16),
              painter: _PulsePainter(_c.value, widget.color, widget.size),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t, this.color, this.dot);

  final double t;
  final Color color;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringAlpha = 0.6 * (1 - t).clamp(0.0, 1.0);
    if (ringAlpha > 0) {
      canvas.drawCircle(
        center,
        dot / 2 + t * 7,
        Paint()..color = color.withValues(alpha: ringAlpha),
      );
    }
    canvas.drawCircle(center, dot / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color || old.dot != dot;
}
