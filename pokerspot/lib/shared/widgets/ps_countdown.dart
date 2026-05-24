import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport live countdown (mockup `.countdown`): ticks every second toward
/// [deadline], showing `mm:ss` (or `expired`). Used for reservation / called
/// holds. [color] defaults to status-live.
class PsCountdown extends StatefulWidget {
  const PsCountdown({
    super.key,
    required this.deadline,
    this.color = PsColors.statusLive,
    this.expiredLabel = 'expired',
    this.style,
  });

  final DateTime deadline;
  final Color color;
  final String expiredLabel;
  final TextStyle? style;

  @override
  State<PsCountdown> createState() => _PsCountdownState();
}

class _PsCountdownState extends State<PsCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _text() {
    final left = widget.deadline.difference(DateTime.now());
    if (left.isNegative) return widget.expiredLabel;
    final m = left.inMinutes;
    final s = left.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text(),
      style: (widget.style ??
              const TextStyle(fontSize: PsType.subhead, fontWeight: PsType.weightBlack))
          .copyWith(color: widget.color, fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
