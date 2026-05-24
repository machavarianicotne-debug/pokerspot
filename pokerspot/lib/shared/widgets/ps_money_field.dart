import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport money input (mockup `.money`): a glass row with a leading
/// currency [symbol] and a numeric field. 50px min-height, radius-md.
class PsMoneyField extends StatelessWidget {
  const PsMoneyField({
    super.key,
    required this.symbol,
    this.controller,
    this.hintText,
    this.onChanged,
  });

  final String symbol;
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4),
      decoration: BoxDecoration(
        color: PsColors.glassThin,
        borderRadius: BorderRadius.circular(PsRadii.md),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: PsType.headline,
              fontWeight: PsType.weightBlack,
              color: PsColors.textMuted,
            ),
          ),
          const SizedBox(width: PsSpacing.s2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              cursorColor: PsColors.accentSecondary,
              style: const TextStyle(
                fontSize: PsType.headline,
                fontWeight: PsType.weightBold,
                color: PsColors.text,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: PsType.headline,
                  fontWeight: PsType.weightMedium,
                  color: PsColors.textFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
