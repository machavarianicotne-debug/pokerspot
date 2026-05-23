import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';

void main() {
  test('phone must be E.164', () {
    expect(ValidationRules.isValidPhone('+995599123456'), isTrue);
    expect(ValidationRules.isValidPhone('+995 599 12 34 56'), isTrue); // spaces stripped
    expect(ValidationRules.isValidPhone('599123456'), isFalse);        // no +
    expect(ValidationRules.isValidPhone('+12'), isFalse);              // too short
  });

  test('display name needs >= 2 trimmed chars', () {
    expect(ValidationRules.isValidName('Giorgi'), isTrue);
    expect(ValidationRules.isValidName(' A '), isFalse);
    expect(ValidationRules.isValidName(''), isFalse);
  });
}
