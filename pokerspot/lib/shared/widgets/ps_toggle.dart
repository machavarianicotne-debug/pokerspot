import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport toggle (`.ps-toggle`): a 42×25 glass track with a white thumb
/// that slides right and turns the track accent-secondary when [value] is true.
/// Controlled — the parent owns [value] and updates it in [onChanged].
class PsToggle extends StatelessWidget {
  const PsToggle({super.key, required this.value, required this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final track = AnimatedContainer(
      duration: PsMotion.normal,
      curve: PsMotion.ease,
      width: 42,
      height: 25,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? PsColors.accentSecondary : PsColors.glassRegular,
        borderRadius: BorderRadius.circular(PsRadii.full),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: AnimatedAlign(
        duration: PsMotion.normal,
        curve: PsMotion.ease,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: const SizedBox(
          width: 19,
          height: 19,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          track,
          if (label != null) ...[
            const SizedBox(width: 7),
            Text(
              label!,
              style: TextStyle(
                fontSize: PsType.caption,
                fontWeight: PsType.weightBold,
                color: PsColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
