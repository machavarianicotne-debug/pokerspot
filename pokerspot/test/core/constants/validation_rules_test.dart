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

  test('first/last name need >= 2 trimmed chars', () {
    expect(ValidationRules.isValidFirstName('Gio'), isTrue);
    expect(ValidationRules.isValidFirstName('Be'), isTrue);
    expect(ValidationRules.isValidFirstName(' a '), isFalse); // 1 trimmed char
    expect(ValidationRules.isValidFirstName(''), isFalse);

    expect(ValidationRules.isValidLastName('Beridze'), isTrue);
    expect(ValidationRules.isValidLastName(' b '), isFalse);
    expect(ValidationRules.isValidLastName(''), isFalse);
  });

  test('first and last names must differ (trimmed, case-insensitive)', () {
    expect(ValidationRules.firstAndLastNamesDiffer('Giorgi', 'Beridze'), isTrue);
    // identical
    expect(ValidationRules.firstAndLastNamesDiffer('Giorgi', 'Giorgi'), isFalse);
    // case-insensitive equality
    expect(ValidationRules.firstAndLastNamesDiffer('john', 'JOHN'), isFalse);
    // trimmed equality
    expect(ValidationRules.firstAndLastNamesDiffer('  Nino ', 'nino'), isFalse);
    // differ after trimming/lowercasing
    expect(ValidationRules.firstAndLastNamesDiffer(' Nino ', 'Nina'), isTrue);
  });
}
