import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport stake pill (`.ps-stake-pill`): a small glass chip showing a
/// game [type] (e.g. `NLH`, accent-primary + black) next to its [value] (e.g.
/// `1/2 GEL`, in the regular text colour).
class PsStakePill extends StatelessWidget {
  const PsStakePill({super.key, required this.type, required this.value});

  final String type;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: PsColors.glassRegular,
        borderRadius: BorderRadius.circular(PsRadii.full),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: const TextStyle(
              fontSize: PsType.caption,
              fontWeight: PsType.weightBlack,
              color: PsColors.accentPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: PsType.caption,
              fontWeight: PsType.weightBold,
              color: PsColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
