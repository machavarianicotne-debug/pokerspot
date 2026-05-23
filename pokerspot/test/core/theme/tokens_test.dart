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
}
