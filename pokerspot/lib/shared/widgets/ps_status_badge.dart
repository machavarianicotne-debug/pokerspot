import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';

enum PsStatus { live, open, closed }

/// Liquid Sport status badge (`.ps-status-badge`): a small uppercase overline
/// chip. `live` is a solid red badge with a white [PsLiveDot]; `open` is a
/// tinted amber chip; `closed` is muted glass.
class PsStatusBadge extends StatelessWidget {
  const PsStatusBadge({super.key, required this.status, required this.label});

  final PsStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case PsStatus.live:
        bg = PsColors.statusLive;
        fg = Colors.white;
      case PsStatus.open:
        bg = PsColors.statusOpen.withValues(alpha: 0.18);
        fg = PsColors.statusOpen;
      case PsStatus.closed:
        bg = PsColors.glassThin;
        fg = PsColors.textFaint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PsRadii.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == PsStatus.live) ...[
            const PsLiveDot(color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: PsType.micro,
              fontWeight: PsType.weightBlack,
              letterSpacing: PsType.trackingOverline,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
