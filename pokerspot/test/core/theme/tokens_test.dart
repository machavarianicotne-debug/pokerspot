import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  test('Liquid Sport accent + bg match tokens.css', () {
    expect(PsColors.accentPrimary, const Color(0xFFC6FF3A));
    expect(PsColors.accentSecondary, const Color(0xFF34E3FF));
    expect(PsColors.onAccent, const Color(0xFF06241A));
    expect(PsColors.statusLive, const Color(0xFFFF4D57));
    expect(PsColors.bg0, const Color(0xFF04151A));
  });

  test('8pt spacing scale', () {
    expect(PsSpacing.s1, 4);
    expect(PsSpacing.s4, 16);
    expect(PsSpacing.s12, 48);
  });

  test('type scale + radii', () {
    expect(PsType.display1, 42);
    expect(PsType.body, 15);
    expect(PsRadii.lg, 20);
    expect(PsRadii.full, 999);
  });

  test('new color tokens (Design Polish)', () {
    expect(PsColors.statusFull, const Color(0xFFFF4D57));
    expect(PsColors.glassThick.a, closeTo(0.14, 0.001));
    expect(PsColors.glassHighlight.a, closeTo(0.30, 0.001));
    expect(PsColors.bgBloomA.a, closeTo(0.16, 0.001));
    expect(PsColors.bgBloomB.a, closeTo(0.12, 0.001));
  });

  test('glass blur tiers + saturation matrix', () {
    expect(PsGlass.blurThin, 16);
    expect(PsGlass.blurRegular, 22);
    expect(PsGlass.blurThick, 30);
    expect(PsGlass.saturate, 1.70);
    // 4x5 saturate matrix, alpha row preserved.
    expect(PsGlass.saturationMatrix.length, 20);
    expect(PsGlass.saturationMatrix.sublist(15), [0, 0, 0, 1, 0]);
  });

  test('type weights + tracking', () {
    expect(PsType.weightBlack, FontWeight.w900);
    expect(PsType.weightBold, FontWeight.w800);
    expect(PsType.trackingTight, -1);
    expect(PsType.trackingOverline, 1.2);
  });

  test('elevation shadows', () {
    expect(PsElevation.e1, isNotEmpty);
    expect(PsElevation.e4.first.spreadRadius, -22);
    expect(PsElevation.e5.first.blurRadius, 60);
  });

  test('gradients + motion + layout', () {
    expect(PsGradients.backgroundBase.colors, [PsColors.bg1, PsColors.bg0]);
    expect(PsGradients.avatar.colors.first, PsColors.accentSecondary);
    expect(PsMotion.easeDecelerate, const Cubic(0, 0, 0.2, 1));
    expect(PsMotion.easeAccelerate, const Cubic(0.4, 0, 1, 1));
    expect(PsLayout.screenPad, 16);
  });
}
