import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Builds ThemeData from the design tokens (spec §12.E).
abstract final class AppTheme {
  static ThemeData liquidSport() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: PsColors.bg0,
      // iOS-style horizontal slide on every platform: a pushed screen enters
      // from the right, and on back the previous screen returns from the left.
      // Without this, non-iOS (incl. web) uses the Material zoom/fade.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: PsColors.accentPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: PsColors.accentPrimary,
        secondary: PsColors.accentSecondary,
        onPrimary: PsColors.onAccent,
        surface: PsColors.bg1,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: PsColors.text,
        displayColor: PsColors.text,
      ),
    );
  }
}
