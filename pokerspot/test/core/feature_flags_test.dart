import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/feature_flags.dart';

void main() {
  test('MVP defaults match spec §12.B', () {
    const f = FeatureFlags.mvp();
    expect(f.clubChat, isTrue);
    expect(f.perSeatIdentity, isTrue);
    expect(f.multiClubPitBoss, isFalse);
    expect(f.autoReservationConvertToWaitlist, isFalse);
    expect(f.deepAnalytics, isFalse);
    expect(f.geoMap, isFalse);
    expect(f.templateAutoRestore, isFalse);
    expect(f.crossClubWaitlist, isFalse);
    expect(f.iosSupport, isFalse);
  });

  test('copyWith overrides a single flag (per-env override)', () {
    const f = FeatureFlags.mvp();
    expect(f.copyWith(deepAnalytics: true).deepAnalytics, isTrue);
    expect(f.copyWith(deepAnalytics: true).clubChat, isTrue);
  });
}
