import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport avatar (`.ps-avatar`): a circular cyan→blue gradient chip with
/// centered initials. Font scales with [size] (subhead at the default 34px).
class PsAvatar extends StatelessWidget {
  const PsAvatar({super.key, required this.initials, this.size = 34});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: PsGradients.avatar, shape: BoxShape.circle),
        child: Text(
          initials,
          style: TextStyle(
            color: PsColors.onAccent,
            fontWeight: PsType.weightBold,
            fontSize: size * (PsType.subhead / 34),
          ),
        ),
      ),
    );
  }
}
