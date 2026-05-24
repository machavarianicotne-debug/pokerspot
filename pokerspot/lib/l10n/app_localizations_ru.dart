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

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get phoneHint => '+995 5XX XX XX XX';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get smsCode => 'SMS-код';

  @override
  String get smsHint => '6-значный код';

  @override
  String get verify => 'Подтвердить';

  @override
  String get invalidPhone => 'Введите корректный номер +995';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get nameHint => 'напр. Гиорги';

  @override
  String get getStarted => 'Начать';

  @override
  String get language => 'Язык';

  @override
  String get signOut => 'Выйти';

  @override
  String get playerHome => 'Игрок';

  @override
  String get pitBossHome => 'Pit Boss';

  @override
  String get superAdminHome => 'Super Admin';

  @override
  String get firstName => 'Имя';

  @override
  String get firstNameHint => 'напр. Гиорги';

  @override
  String get lastName => 'Фамилия';

  @override
  String get lastNameHint => 'напр. Беридзе';

  @override
  String get nameTooShort => 'Минимум 2 символа';

  @override
  String get namesMustDiffer => 'Имя и фамилия должны различаться';

  @override
  String get clubsListTitle => 'Клубы';

  @override
  String get noClubsYet => 'Пока нет клубов';

  @override
  String get clubAddress => 'Адрес';

  @override
  String get clubHours => 'Часы работы';

  @override
  String get clubPhone => 'Телефон';

  @override
  String get tablesComingSoon => 'Столы — в следующем релизе';

  @override
  String get backToClubs => 'Назад к клубам';
}
