// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PokerSpot';

  @override
  String get welcomeTitle => 'Welcome to PokerSpot';

  @override
  String get gdprConsent =>
      'PokerSpot tracks your play sessions for personal stats and club reports. By continuing you consent.';
}
