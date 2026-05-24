import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport list-tile: a content row for the club / waitlist / session
/// cards — optional [leading], a bold [title] over a muted [subtitle], and an
/// optional [trailing]. Carries no surface of its own; host it inside a
/// [PsCard]. Replaces Material `ListTile` (no Material insets/ink).
class PsListTile extends StatelessWidget {
  const PsListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: PsSpacing.s3)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: PsType.body,
                  fontWeight: PsType.weightBold,
                  color: PsColors.text,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightMedium,
                    color: PsColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: PsSpacing.s3), trailing!],
      ],
    );
  }
}
