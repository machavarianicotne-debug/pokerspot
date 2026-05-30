import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Design tokens — Liquid Sport. Ported 1:1 from
/// docs/superpowers/mockups/v3-design-system/tokens.css. Change a value here →
/// the whole app re-skins (spec §12.E). Extended in the Design Polish pass to
/// cover every value the mockups use (see docs/design-system/liquid-sport.md).
abstract final class PsColors {
  static const accentPrimary = Color(0xFFC6FF3A);
  static const accentSecondary = Color(0xFF34E3FF);
  static const onAccent = Color(0xFF06241A);

  static const statusLive = Color(0xFFFF4D57);
  static const statusOpen = Color(0xFFFFB02E);
  static const statusClosed = Color(0xFF56646A);
  static const statusFull = Color(0xFFFF4D57);

  static const bg0 = Color(0xFF04151A);
  static const bg1 = Color(0xFF062A2C);

  /// Background blooms (radial gradient overlays) — see [PsGradients].
  static final bgBloomA = const Color(0xFF34E3FF).withValues(alpha: 0.16); // cyan
  static final bgBloomB = const Color(0xFFC6FF3A).withValues(alpha: 0.12); // lime

  static const text = Color(0xFFECFBFF);
  static final textMuted = const Color(0xFFECFBFF).withValues(alpha: 0.56);
  static final textFaint = const Color(0xFFECFBFF).withValues(alpha: 0.32);

  // ---- Glass materials (Liquid Glass) --------------------------------------
  static final glassThin = Colors.white.withValues(alpha: 0.05);
  static final glassRegular = Colors.white.withValues(alpha: 0.085);
  static final glassThick = Colors.white.withValues(alpha: 0.14);
  static final glassBorder = Colors.white.withValues(alpha: 0.11);
  static final glassHighlight = Colors.white.withValues(alpha: 0.30);
}

/// Glass blur radii + saturation (Liquid Glass material tiers).
abstract final class PsGlass {
  static const double blurThin = 16, blurRegular = 22, blurThick = 30;

  /// CSS `saturate(170%)` factor.
  static const double saturate = 1.70;

  /// `saturate(170%)` as a 4x5 ColorFilter matrix (SVG feColorMatrix "saturate"
  /// formula with the CSS luma coefficients 0.213/0.715/0.072; alpha preserved).
  /// Centralizes the glass saturation so every glass surface matches the mockup
  /// (CSS `backdrop-filter: blur() saturate(170%)`) — not blur-only.
  static const List<double> saturationMatrix = <double>[
    1.5509, -0.5005, -0.0504, 0, 0, //
    -0.1491, 1.1995, -0.0504, 0, 0, //
    -0.1491, -0.5005, 1.6496, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// Combined Liquid Glass backdrop filter for [BackdropFilter]: blur THEN
  /// saturation, applied to the backdrop (matches the mockup exactly).
  static ImageFilter backdrop(double blur) => ImageFilter.compose(
        outer: const ColorFilter.matrix(saturationMatrix),
        inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      );
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

  // Letters nudged one step heavier across the board (per request: thicker, not
  // larger). Regular/medium carry most body text so they gain the most weight;
  // bold/black are already near the ceiling.
  static const FontWeight weightRegular = FontWeight.w500;
  static const FontWeight weightMedium = FontWeight.w700;
  static const FontWeight weightBold = FontWeight.w800;
  static const FontWeight weightBlack = FontWeight.w900;

  static const double trackingTight = -1,
      trackingSnug = -0.4,
      trackingNormal = 0,
      trackingWide = 0.8,
      trackingOverline = 1.2;
}

/// Elevation shadows (ported from tokens.css; negative spread = CSS `-Npx`).
abstract final class PsElevation {
  static final List<BoxShadow> e1 = [
    BoxShadow(offset: const Offset(0, 2), blurRadius: 6, spreadRadius: -3, color: Colors.black.withValues(alpha: 0.5)),
  ];
  static final List<BoxShadow> e2 = [
    BoxShadow(offset: const Offset(0, 8), blurRadius: 18, spreadRadius: -10, color: Colors.black.withValues(alpha: 0.6)),
  ];
  static final List<BoxShadow> e3 = [
    BoxShadow(offset: const Offset(0, 16), blurRadius: 30, spreadRadius: -18, color: Colors.black.withValues(alpha: 0.7)),
  ];
  static final List<BoxShadow> e4 = [
    BoxShadow(offset: const Offset(0, 22), blurRadius: 40, spreadRadius: -22, color: Colors.black.withValues(alpha: 0.85)),
  ];
  static final List<BoxShadow> e5 = [
    BoxShadow(offset: const Offset(0, 30), blurRadius: 60, spreadRadius: -26, color: Colors.black.withValues(alpha: 0.92)),
  ];
}

/// Gradients. The background is composed from [backgroundBase] + the two radial
/// blooms (PsColors.bgBloomA/B) by PsScaffold.
abstract final class PsGradients {
  static const LinearGradient backgroundBase = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PsColors.bg1, PsColors.bg0],
  );

  /// 135° avatar gradient (accent-secondary -> #0A84FF).
  static const LinearGradient avatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PsColors.accentSecondary, Color(0xFF0A84FF)],
  );

  /// Top specular highlight line on glass (transparent -> highlight -> transparent).
  static LinearGradient get glassHighlightLine => LinearGradient(
        colors: [Colors.transparent, PsColors.glassHighlight, Colors.transparent],
      );
}

abstract final class PsMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const ease = Cubic(0.22, 0.61, 0.36, 1);
  static const easeDecelerate = Cubic(0, 0, 0.2, 1);
  static const easeAccelerate = Cubic(0.4, 0, 1, 1);
}

abstract final class PsLayout {
  static const double screenPad = PsSpacing.s4;
}
