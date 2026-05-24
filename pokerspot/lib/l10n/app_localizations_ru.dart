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
  String get welcomeSub =>
      'Найдите живой покер по всей Грузии — смотрите свободные места и вставайте в лист ожидания.';

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
  String get tabClubs => 'Клубы';

  @override
  String get tabActivity => 'Активность';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get tabFloor => 'Зал';

  @override
  String get tabTables => 'Столы';

  @override
  String get tabOverview => 'Обзор';

  @override
  String get noActivityYet => 'Пока ничего нет';

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

  @override
  String get phoneCopied => 'Номер скопирован';

  @override
  String get joinWaitlist => 'Встать в очередь';

  @override
  String get chooseStake => 'Выберите лимит';

  @override
  String get noStakesYet => 'Пока нет доступных лимитов';

  @override
  String get joinedWaitlist => 'Вы в очереди';

  @override
  String get yourWaitlist => 'Ваша очередь';

  @override
  String get statusWaiting => 'Ожидание';

  @override
  String get statusCalled => 'Вас вызвали!';

  @override
  String get cancelWaitlist => 'Отменить';

  @override
  String get waitlistTitle => 'Очередь';

  @override
  String get noClubAssigned => 'К вашему аккаунту не привязан клуб';

  @override
  String get waitlistEmpty => 'Никто не ожидает';

  @override
  String get callAction => 'Вызвать';

  @override
  String get seatAction => 'Посадить';

  @override
  String get chooseTable => 'Выберите стол';

  @override
  String get seatNumber => 'Номер места';

  @override
  String get seatedTitle => 'Игроки за столами';

  @override
  String get endSession => 'Завершить';

  @override
  String get tableLabel => 'Стол';

  @override
  String get noTablesYet => 'Столов пока нет';

  @override
  String get newTable => 'Новый стол';

  @override
  String get editTable => 'Редактировать стол';

  @override
  String get deleteTable => 'Удалить стол';

  @override
  String get deleteTableConfirm => 'Удалить этот стол?';

  @override
  String get tableNumberLabel => 'Номер стола';

  @override
  String get seatsLabel => 'Места';

  @override
  String get gameLabel => 'Игра';

  @override
  String get smallBlindLabel => 'Малый блайнд';

  @override
  String get bigBlindLabel => 'Большой блайнд';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String get openLabel => 'Открыт';

  @override
  String get saveLabel => 'Сохранить';

  @override
  String get walkInLabel => 'Walk-in';

  @override
  String get seatWhoTitle => 'Кто садится?';
}
