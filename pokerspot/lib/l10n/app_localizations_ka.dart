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
}
