// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PokerSpot';

  @override
  String get welcomeTitle => 'Добро пожаловать в PokerSpot';

  @override
  String get gdprConsent =>
      'PokerSpot отслеживает ваши игровые сессии для личной статистики и отчётов клубов. Продолжая, вы соглашаетесь.';
}
