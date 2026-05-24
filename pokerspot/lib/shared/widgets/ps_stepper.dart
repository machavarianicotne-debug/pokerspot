import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport stepper (mockup `.stepper`): round −/+ glass buttons around a
/// big display-2 tabular value, clamped to [min]..[max].
class PsStepper extends StatelessWidget {
  const PsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9,
    this.unit,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(symbol: '−', enabled: value > min, onTap: () => onChanged(value - 1)),
        const SizedBox(width: PsSpacing.s4),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: PsType.display2,
              fontWeight: PsType.weightBlack,
              color: PsColors.text,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: PsSpacing.s4),
        _StepBtn(symbol: '+', enabled: value < max, onTap: () => onChanged(value + 1)),
        if (unit != null) ...[
          const SizedBox(width: PsSpacing.s3),
          Text(unit!, style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted)),
        ],
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.symbol, required this.enabled, required this.onTap});
  final String symbol;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PsColors.glassRegular,
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Text(
            symbol,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: PsType.weightBold,
              color: PsColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
