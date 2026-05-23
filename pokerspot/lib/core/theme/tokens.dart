import 'package:flutter/material.dart';

/// Design tokens — Liquid Sport. Ported 1:1 from
/// docs/superpowers/mockups/v3-design-system/tokens.css. Change a value here →
/// the whole app re-skins (spec §12.E).
abstract final class PsColors {
  static const accentPrimary = Color(0xFFC6FF3A);
  static const accentSecondary = Color(0xFF34E3FF);
  static const onAccent = Color(0xFF06241A);

  static const statusLive = Color(0xFFFF4D57);
  static const statusOpen = Color(0xFFFFB02E);
  static const statusClosed = Color(0xFF56646A);

  static const bg0 = Color(0xFF04151A);
  static const bg1 = Color(0xFF062A2C);

  static const text = Color(0xFFECFBFF);
  static final textMuted = const Color(0xFFECFBFF).withValues(alpha: 0.56);
  static final textFaint = const Color(0xFFECFBFF).withValues(alpha: 0.32);

  static final glassThin = Colors.white.withValues(alpha: 0.05);
  static final glassRegular = Colors.white.withValues(alpha: 0.085);
  static final glassBorder = Colors.white.withValues(alpha: 0.11);
}

abstract final class PsSpacing {
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24,
      s8 = 32, s10 = 40, s12 = 48;
}

abstract final class PsRadii {
  static const double sm = 10, md = 14, lg = 20, xl = 26, full = 999;
}

abstract final class PsType {
  static const double display1 = 42, display2 = 30, title = 22, headline = 18,
      body = 15, subhead = 13, caption = 12, micro = 10;
}

abstract final class PsMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const ease = Cubic(0.22, 0.61, 0.36, 1);
}
