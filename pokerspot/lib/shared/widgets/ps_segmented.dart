import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// One option in a [PsSegmented].
class PsSegment<T> {
  const PsSegment(this.value, this.label);
  final T value;
  final String label;
}

/// Liquid Sport segmented control (mockup `.seg`): a glass-regular track holding
/// equal segments; the selected one fills with accent-primary. Used for game
/// type / currency / filters. vs Material SegmentedButton: glass track, accent
/// fill, no Material state layer.
class PsSegmented<T> extends StatelessWidget {
  const PsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<PsSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PsColors.glassRegular,
        borderRadius: BorderRadius.circular(PsRadii.md),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: PsMotion.fast,
                  curve: PsMotion.ease,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.value == value ? PsColors.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(PsRadii.sm),
                  ),
                  child: Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: PsType.subhead,
                      fontWeight: PsType.weightBold,
                      color: s.value == value ? PsColors.onAccent : PsColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
