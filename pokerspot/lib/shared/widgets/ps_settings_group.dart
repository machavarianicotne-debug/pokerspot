import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// A grouped glass settings card (mockup `.sgroup`) — hosts [PsSettingsRow]s
/// separated by hairline borders. Pair with a [PsSettingsGroup.header] overline.
class PsSettingsGroup extends StatelessWidget {
  const PsSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  /// The small faint uppercase group header (mockup `.gh`).
  static Widget header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, PsSpacing.s2),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: PsType.micro,
            fontWeight: PsType.weightBlack,
            letterSpacing: PsType.trackingOverline,
            color: PsColors.textFaint,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Container(height: 1, color: PsColors.glassBorder));
      }
      rows.add(children[i]);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(PsRadii.lg),
      child: BackdropFilter.grouped(
        filter: PsGlass.backdrop(PsGlass.blurRegular),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PsColors.glassThin,
            borderRadius: BorderRadius.circular(PsRadii.lg),
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        ),
      ),
    );
  }
}

/// One row inside a [PsSettingsGroup] (mockup `.srow`): a [label] with a
/// trailing [value] / [trailing] widget; tappable rows show a chevron.
class PsSettingsRow extends StatelessWidget {
  const PsSettingsRow({
    super.key,
    required this.label,
    this.sub,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;

  /// Optional faint sub-text under the label (mockup `.srow .sub`).
  final String? sub;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget end;
    if (trailing != null) {
      end = trailing!;
    } else {
      end = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!, style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted)),
          if (onTap != null) ...[
            const SizedBox(width: PsSpacing.s2),
            Icon(Icons.chevron_right, size: 18, color: PsColors.textFaint),
          ],
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: PsType.body,
                      fontWeight: PsType.weightMedium,
                      color: PsColors.text,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: PsSpacing.s3),
                      child: Text(
                        sub!,
                        style: TextStyle(fontSize: PsType.caption, color: PsColors.textFaint),
                      ),
                    ),
                ],
              ),
            ),
            end,
          ],
        ),
      ),
    );
  }
}
