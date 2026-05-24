import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// The italic, black-weight, tight-tracked PokerSpot wordmark (mockup
/// `.ps-brand`). If [accent] is a substring of [text] it renders in
/// accent-primary while the rest uses [color]; otherwise the whole word is
/// accent-primary.
class PsBrand extends StatelessWidget {
  const PsBrand(
    this.text, {
    super.key,
    this.accent,
    this.fontSize = PsType.title,
    this.color = PsColors.text,
  });

  final String text;
  final String? accent;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: PsType.weightBlack,
      fontStyle: FontStyle.italic,
      letterSpacing: PsType.trackingTight,
      color: color,
    );
    final acc = accent;
    if (acc == null || acc.isEmpty || !text.contains(acc)) {
      return Text(text, style: base.copyWith(color: PsColors.accentPrimary));
    }
    final i = text.indexOf(acc);
    return Text.rich(
      TextSpan(style: base, children: [
        if (i > 0) TextSpan(text: text.substring(0, i)),
        TextSpan(text: acc, style: base.copyWith(color: PsColors.accentPrimary)),
        if (i + acc.length < text.length) TextSpan(text: text.substring(i + acc.length)),
      ]),
    );
  }
}
