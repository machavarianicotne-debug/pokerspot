import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Micro, black-weight, uppercase, wide-tracked label — the mockup's
/// `.ps-overline` (section labels / overlines). Faint by default.
class PsOverline extends StatelessWidget {
  const PsOverline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: PsType.micro,
        fontWeight: PsType.weightBlack,
        letterSpacing: PsType.trackingOverline,
        color: color ?? PsColors.textFaint,
      ),
    );
  }
}
