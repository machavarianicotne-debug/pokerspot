// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Georgian (`ka`).
class AppL10nKa extends AppL10n {
  AppL10nKa([String locale = 'ka']) : super(locale);

  @override
  String get appTitle => 'PokerSpot';

  @override
  String get welcomeTitle => 'მოგესალმებით PokerSpot-ში';

  @override
  String get gdprConsent =>
      'PokerSpot ინახავს თქვენი თამაშის სესიებს პირადი სტატისტიკისა და კლუბის ანგარიშებისთვის. გაგრძელებით თანხმობას აცხადებთ.';

  @override
  String get phoneNumber => 'ტელეფონის ნომერი';

  @override
  String get phoneHint => '+995 5XX XX XX XX';

  @override
  String get sendCode => 'კოდის გაგზავნა';

  @override
  String get smsCode => 'SMS კოდი';

  @override
  String get smsHint => '6-ნიშნა კოდი';

  @override
  String get verify => 'დადასტურება';

  @override
  String get invalidPhone => 'შეიყვანეთ სწორი +995 ნომერი';

  @override
  String get yourName => 'თქვენი სახელი';

  @override
  String get nameHint => 'მაგ. გიორგი';

  @override
  String get getStarted => 'დაწყება';

  @override
  String get language => 'ენა';

  @override
  String get signOut => 'გასვლა';

  @override
  String get playerHome => 'მოთამაშე';

  @override
  String get pitBossHome => 'Pit Boss';

  @override
  String get superAdminHome => 'Super Admin';
}
