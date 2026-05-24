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

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '+995 5XX XX XX XX';

  @override
  String get sendCode => 'Send code';

  @override
  String get smsCode => 'SMS code';

  @override
  String get smsHint => '6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get invalidPhone => 'Enter a valid +995 number';

  @override
  String get yourName => 'Your name';

  @override
  String get nameHint => 'e.g. Giorgi';

  @override
  String get getStarted => 'Get Started';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign out';

  @override
  String get playerHome => 'Player';

  @override
  String get pitBossHome => 'Pit Boss';

  @override
  String get superAdminHome => 'Super Admin';
}
