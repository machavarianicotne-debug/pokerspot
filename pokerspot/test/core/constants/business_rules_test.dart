import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/constants/business_rules.dart';

void main() {
  test('business rules match the spec (§12.A)', () {
    expect(BusinessRules.arrivalDeadlineMinutes, 30);
    expect(BusinessRules.sessionWarningHours, 8);
    expect(BusinessRules.maxPlayersPerTable, 9);
    expect(BusinessRules.maxWaitlistsPerPlayer, isNull); // no cap in MVP
    expect(BusinessRules.defaultCurrency, 'GEL');
    expect(BusinessRules.supportedCurrencies, ['GEL', 'USD', 'EUR']);
    expect(BusinessRules.minBuyInFloor, 1); // > 0
  });
}
