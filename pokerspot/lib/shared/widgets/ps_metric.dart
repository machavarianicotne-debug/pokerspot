import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

enum PsMetricVariant { normal, hero, full }

/// Liquid Sport metric (`.ps-metric`): a scoreboard block — a big tabular
/// display number over a micro uppercase [label], on a glass-regular surface
/// with a top highlight line. `hero` enlarges + accents the value;
/// `full` colours it status-full.
class PsMetric extends StatelessWidget {
  const PsMetric({
    super.key,
    required this.value,
    required this.label,
    this.variant = PsMetricVariant.normal,
  });

  final String value;
  final String label;
  final PsMetricVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color valueColor;
    switch (variant) {
      case PsMetricVariant.hero:
        valueColor = PsColors.accentPrimary;
      case PsMetricVariant.full:
        valueColor = PsColors.statusFull;
      case PsMetricVariant.normal:
        valueColor = PsColors.text;
    }
    final valueSize = variant == PsMetricVariant.hero ? PsType.display1 : PsType.display2;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: PsColors.glassRegular,
        borderRadius: BorderRadius.circular(PsRadii.md),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: PsType.weightBlack,
                  height: 0.9,
                  letterSpacing: PsType.trackingTight,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: PsType.micro,
                  fontWeight: PsType.weightBlack,
                  letterSpacing: PsType.trackingWide,
                  color: PsColors.textFaint,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(gradient: PsGradients.glassHighlightLine),
            ),
          ),
        ],
      ),
    );
  }
}
