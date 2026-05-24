/// Centralized validation (spec §12.A).
abstract final class ValidationRules {
  static const int minNameLength = 2;
  static final RegExp _e164 = RegExp(r'^\+\d{8,15}$');

  static bool isValidPhone(String raw) =>
      _e164.hasMatch(raw.replaceAll(RegExp(r'\s'), ''));

  static bool isValidName(String raw) => raw.trim().length >= minNameLength;

  static bool isValidFirstName(String raw) => raw.trim().length >= minNameLength;

  static bool isValidLastName(String raw) => raw.trim().length >= minNameLength;

  /// True when the two names are distinct (trimmed, case-insensitive).
  static bool firstAndLastNamesDiffer(String first, String last) =>
      first.trim().toLowerCase() != last.trim().toLowerCase();
}
