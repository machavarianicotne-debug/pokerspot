import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// One labelled bar in a [PsBarChart].
class PsBar {
  const PsBar(this.value, this.label);
  final double value;
  final String label;
}

/// Liquid Sport bar chart (mockup 7-day / playtime bars): gradient bars scaled
/// to the max value, with a small label under each. CSS gradient bars → Flutter
/// fractional-height columns (honest approximation; no chart library).
class PsBarChart extends StatelessWidget {
  const PsBarChart({super.key, required this.bars, this.height = 110});

  final List<PsBar> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            if (i > 0) const SizedBox(width: PsSpacing.s2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: max <= 0 ? 0.02 : (bars[i].value / max).clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6), bottom: Radius.circular(3)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                PsColors.accentPrimary,
                                PsColors.accentSecondary.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bars[i].label,
                    style: TextStyle(
                      fontSize: PsType.micro,
                      fontWeight: PsType.weightBold,
                      color: PsColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
