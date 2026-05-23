/// Centralized business rules (spec §12.A). Change a rule here — nowhere else.
abstract final class BusinessRules {
  /// Minutes a held reservation OR a called waitlist entry stays valid.
  static const int arrivalDeadlineMinutes = 30;

  /// A seated session longer than this shows a warning (no auto-end).
  static const int sessionWarningHours = 8;

  /// Default seats per table.
  static const int maxPlayersPerTable = 9;

  /// Max simultaneous waitlists per player; null = no cap in MVP.
  static const int? maxWaitlistsPerPlayer = null;

  static const String defaultCurrency = 'GEL';
  static const List<String> supportedCurrencies = ['GEL', 'USD', 'EUR'];

  /// buyInMin must be > 0 (no maxBuyIn — Tbilisi format is uncapped).
  static const int minBuyInFloor = 1;
}
