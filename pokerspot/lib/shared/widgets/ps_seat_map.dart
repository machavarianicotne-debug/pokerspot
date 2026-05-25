import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport oval felt + seats (mockup `.felt`/`.seat`). Seats are arranged
/// in a ring (trig-positioned, starting at the top), filled seats glow
/// accent-primary, [warnSeats] glow status-open (e.g. >8h sessions), empty
/// seats are tappable. The centre shows open/total. Replaces the seat-dropdown.
class PsSeatMap extends StatelessWidget {
  const PsSeatMap({
    super.key,
    required this.seatCount,
    required this.filledSeats,
    this.warnSeats = const {},
    this.heldSeats = const {},
    this.onSeatTap,
    this.height = 150,
  });

  final int seatCount;
  final Set<int> filledSeats;
  final Set<int> warnSeats;

  /// Seats reserved/called for a player (status held) — shown red, blocked.
  final Set<int> heldSeats;
  final void Function(int seat)? onSeatTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final open = seatCount - filledSeats.length - heldSeats.length;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 320.0;
        final cx = w / 2, cy = height / 2;
        final rx = w * 0.40, ry = height * 0.38;
        return SizedBox(
          width: w,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: PsColors.glassThin,
                    borderRadius: BorderRadius.circular(80),
                    border: Border.all(color: PsColors.glassBorder),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.3),
                      radius: 0.9,
                      colors: [PsColors.accentSecondary.withValues(alpha: 0.10), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: PsType.display2,
                          fontWeight: PsType.weightBlack,
                          height: 1,
                          color: PsColors.text,
                        ),
                        children: open > 0
                            ? [
                                TextSpan(text: '$open',
                                    style: const TextStyle(color: PsColors.accentPrimary)),
                                TextSpan(text: '/$seatCount'),
                              ]
                            : [TextSpan(text: '$seatCount/$seatCount')],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      open > 0 ? 'OPEN' : 'FULL',
                      style: TextStyle(
                        fontSize: PsType.micro,
                        fontWeight: PsType.weightBlack,
                        letterSpacing: PsType.trackingWide,
                        color: PsColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              for (int i = 0; i < seatCount; i++) _positioned(i, cx, cy, rx, ry),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(int i, double cx, double cy, double rx, double ry) {
    final seat = i + 1;
    final ang = i / seatCount * 2 * math.pi - math.pi / 2;
    final held = heldSeats.contains(seat);
    final filled = filledSeats.contains(seat);
    final warn = warnSeats.contains(seat);
    final occupied = held || filled || warn;
    final color = held
        ? PsColors.statusLive
        : warn
            ? PsColors.statusOpen
            : filled
                ? PsColors.accentPrimary
                : PsColors.bg1;
    return Positioned(
      left: cx + rx * math.cos(ang) - 13,
      top: cy + ry * math.sin(ang) - 13,
      child: GestureDetector(
        onTap: onSeatTap == null ? null : () => onSeatTap!(seat),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: occupied ? color : PsColors.glassBorder,
              width: 2,
            ),
            boxShadow: occupied
                ? [BoxShadow(color: color, blurRadius: 8, spreadRadius: -1)]
                : null,
          ),
        ),
      ),
    );
  }
}
