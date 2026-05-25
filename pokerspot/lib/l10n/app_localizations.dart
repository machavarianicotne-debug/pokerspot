import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ka'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PokerSpot'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PokerSpot'**
  String get welcomeTitle;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Find live poker across Georgia — see open seats and join waitlists.'**
  String get welcomeSub;

  /// No description provided for @gdprConsent.
  ///
  /// In en, this message translates to:
  /// **'PokerSpot tracks your play sessions for personal stats and club reports. By continuing you consent.'**
  String get gdprConsent;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+995 5XX XX XX XX'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get smsCode;

  /// No description provided for @smsHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get smsHint;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid +995 number'**
  String get invalidPhone;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Giorgi'**
  String get nameHint;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @playerHome.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerHome;

  /// No description provided for @pitBossHome.
  ///
  /// In en, this message translates to:
  /// **'Pit Boss'**
  String get pitBossHome;

  /// No description provided for @superAdminHome.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdminHome;

  /// No description provided for @tabClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get tabClubs;

  /// No description provided for @tabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get tabFloor;

  /// No description provided for @tabTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tabTables;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing on your list yet'**
  String get noActivityYet;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Giorgi'**
  String get firstNameHint;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Beridze'**
  String get lastNameHint;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Min 2 characters'**
  String get nameTooShort;

  /// No description provided for @namesMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'First and last name must be different'**
  String get namesMustDiffer;

  /// No description provided for @clubsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get clubsListTitle;

  /// No description provided for @noClubsYet.
  ///
  /// In en, this message translates to:
  /// **'No clubs yet'**
  String get noClubsYet;

  /// No description provided for @clubAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clubAddress;

  /// No description provided for @clubHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get clubHours;

  /// No description provided for @clubPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get clubPhone;

  /// No description provided for @tablesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tables — coming in the next release'**
  String get tablesComingSoon;

  /// No description provided for @backToClubs.
  ///
  /// In en, this message translates to:
  /// **'Back to clubs'**
  String get backToClubs;

  /// No description provided for @phoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneCopied;

  /// No description provided for @joinWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Join waitlist'**
  String get joinWaitlist;

  /// No description provided for @chooseStake.
  ///
  /// In en, this message translates to:
  /// **'Choose a stake'**
  String get chooseStake;

  /// No description provided for @noStakesYet.
  ///
  /// In en, this message translates to:
  /// **'No stakes available yet'**
  String get noStakesYet;

  /// No description provided for @joinedWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Added to the waitlist'**
  String get joinedWaitlist;

  /// No description provided for @yourWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Your waitlist'**
  String get yourWaitlist;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusCalled.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been called!'**
  String get statusCalled;

  /// No description provided for @cancelWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelWaitlist;

  /// No description provided for @waitlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get waitlistTitle;

  /// No description provided for @noClubAssigned.
  ///
  /// In en, this message translates to:
  /// **'No club is assigned to your account'**
  String get noClubAssigned;

  /// No description provided for @waitlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one is waiting'**
  String get waitlistEmpty;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @seatAction.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get seatAction;

  /// No description provided for @chooseTable.
  ///
  /// In en, this message translates to:
  /// **'Choose a table'**
  String get chooseTable;

  /// No description provided for @seatNumber.
  ///
  /// In en, this message translates to:
  /// **'Seat number'**
  String get seatNumber;

  /// No description provided for @seatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seated players'**
  String get seatedTitle;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endSession;

  /// No description provided for @tableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableLabel;

  /// No description provided for @noTablesYet.
  ///
  /// In en, this message translates to:
  /// **'No tables yet'**
  String get noTablesYet;

  /// No description provided for @newTable.
  ///
  /// In en, this message translates to:
  /// **'New table'**
  String get newTable;

  /// No description provided for @editTable.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get editTable;

  /// No description provided for @deleteTable.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get deleteTable;

  /// No description provided for @deleteTableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this table?'**
  String get deleteTableConfirm;

  /// No description provided for @tableNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Table number'**
  String get tableNumberLabel;

  /// No description provided for @seatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seatsLabel;

  /// No description provided for @gameLabel.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameLabel;

  /// No description provided for @smallBlindLabel.
  ///
  /// In en, this message translates to:
  /// **'Small blind'**
  String get smallBlindLabel;

  /// No description provided for @bigBlindLabel.
  ///
  /// In en, this message translates to:
  /// **'Big blind'**
  String get bigBlindLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @walkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkInLabel;

  /// No description provided for @seatWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s sitting?'**
  String get seatWhoTitle;

  /// No description provided for @tabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabUsers;

  /// No description provided for @newClub.
  ///
  /// In en, this message translates to:
  /// **'New club'**
  String get newClub;

  /// No description provided for @editClub.
  ///
  /// In en, this message translates to:
  /// **'Edit club'**
  String get editClub;

  /// No description provided for @clubNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get clubNameLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @enabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledLabel;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get searchUsersHint;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockLabel;

  /// No description provided for @assignClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get assignClubLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @sessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// No description provided for @avgMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg min'**
  String get avgMinLabel;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @blindsLabel.
  ///
  /// In en, this message translates to:
  /// **'Blinds'**
  String get blindsLabel;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @minBuyInLabel.
  ///
  /// In en, this message translates to:
  /// **'Min buy-in'**
  String get minBuyInLabel;

  /// No description provided for @avgStackLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg stack'**
  String get avgStackLabel;

  /// No description provided for @tablesToOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Tables to open'**
  String get tablesToOpenLabel;

  /// No description provided for @openGameBtn.
  ///
  /// In en, this message translates to:
  /// **'Open game'**
  String get openGameBtn;

  /// No description provided for @reserveSeat.
  ///
  /// In en, this message translates to:
  /// **'Reserve a seat'**
  String get reserveSeat;

  /// No description provided for @reserveNow.
  ///
  /// In en, this message translates to:
  /// **'Reserve now'**
  String get reserveNow;

  /// No description provided for @holdInfoText.
  ///
  /// In en, this message translates to:
  /// **'Instant hold. If a seat is open we hold it 30 minutes; otherwise you join the waitlist.'**
  String get holdInfoText;

  /// No description provided for @seatHeldTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat held for 30 min'**
  String get seatHeldTitle;

  /// No description provided for @reservedBadge.
  ///
  /// In en, this message translates to:
  /// **'Seat held'**
  String get reservedBadge;

  /// No description provided for @accountHeader.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountHeader;

  /// No description provided for @notificationsHeader.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsHeader;

  /// No description provided for @sessionHeader.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionHeader;

  /// No description provided for @notifSeatCalled.
  ///
  /// In en, this message translates to:
  /// **'Seat called'**
  String get notifSeatCalled;

  /// No description provided for @notifReservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation updates'**
  String get notifReservation;

  /// No description provided for @notifClubNews.
  ///
  /// In en, this message translates to:
  /// **'Club news'**
  String get notifClubNews;

  /// No description provided for @chatWithPitBoss.
  ///
  /// In en, this message translates to:
  /// **'Chat with Pit Boss'**
  String get chatWithPitBoss;

  /// No description provided for @chatEntrySub.
  ///
  /// In en, this message translates to:
  /// **'Dress code, parking, VIP — ask the floor'**
  String get chatEntrySub;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message the floor…'**
  String get messageHint;

  /// No description provided for @tabInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get tabInbox;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get inboxEmpty;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @registeredLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registeredLabel;

  /// No description provided for @availabilityHeader.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityHeader;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepting players'**
  String get availableLabel;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noStatsYet;

  /// No description provided for @tabPitBosses.
  ///
  /// In en, this message translates to:
  /// **'Pit Bosses'**
  String get tabPitBosses;

  /// No description provided for @activeAssignmentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Active assignments'**
  String get activeAssignmentsHeader;

  /// No description provided for @assignPitBossHeader.
  ///
  /// In en, this message translates to:
  /// **'Assign a Pit Boss'**
  String get assignPitBossHeader;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @assignBtn.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignBtn;

  /// No description provided for @noUserForPhone.
  ///
  /// In en, this message translates to:
  /// **'No registered user with that phone'**
  String get noUserForPhone;

  /// No description provided for @seatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get seatedLabel;

  /// No description provided for @reservationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservationsTitle;

  /// No description provided for @heldLabel.
  ///
  /// In en, this message translates to:
  /// **'held'**
  String get heldLabel;

  /// No description provided for @arrivedAction.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrivedAction;

  /// No description provided for @reservedHint.
  ///
  /// In en, this message translates to:
  /// **'Seat held · player arrives within 30 min or it\'s released'**
  String get reservedHint;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @availableForChat.
  ///
  /// In en, this message translates to:
  /// **'Available for chat'**
  String get availableForChat;

  /// No description provided for @availableForChatSub.
  ///
  /// In en, this message translates to:
  /// **'When off, players see \"Pit Boss unavailable\" and can\'t start new chats.'**
  String get availableForChatSub;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @notifNewWaitlist.
  ///
  /// In en, this message translates to:
  /// **'New waitlist join'**
  String get notifNewWaitlist;

  /// No description provided for @notifNewReservation.
  ///
  /// In en, this message translates to:
  /// **'New reservation request'**
  String get notifNewReservation;

  /// No description provided for @notifNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat message'**
  String get notifNewChat;

  /// No description provided for @notifReservationDecision.
  ///
  /// In en, this message translates to:
  /// **'Reservation accepted / rejected'**
  String get notifReservationDecision;

  /// No description provided for @notifDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get notifDailySummary;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @languageHeader.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageHeader;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// No description provided for @liveLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveLabel;

  /// No description provided for @closedLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLabel;

  /// No description provided for @openSeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open seats'**
  String get openSeatsLabel;

  /// No description provided for @stakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stakes'**
  String get stakesLabel;

  /// No description provided for @noSeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'No seats'**
  String get noSeatsLabel;

  /// No description provided for @fullLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL'**
  String get fullLabel;

  /// No description provided for @floorOpenEmpty.
  ///
  /// In en, this message translates to:
  /// **'Floor open — no games running yet tonight.'**
  String get floorOpenEmpty;

  /// No description provided for @allCitiesFilter.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get allCitiesFilter;

  /// No description provided for @liveCountLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveCountLabel;

  /// No description provided for @liveGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Live games'**
  String get liveGamesTitle;

  /// No description provided for @noGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'No games running'**
  String get noGamesTitle;

  /// No description provided for @noGamesSub.
  ///
  /// In en, this message translates to:
  /// **'The floor is open — check back later, or reserve a seat for tonight.'**
  String get noGamesSub;

  /// No description provided for @tablesMetric.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesMetric;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minLabel;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newChat;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send — check your connection or that a club is assigned to you.'**
  String get chatSendFailed;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Currently playing'**
  String get nowPlaying;

  /// No description provided for @nowPlayingHint.
  ///
  /// In en, this message translates to:
  /// **'Ends when the Pit Boss marks you left'**
  String get nowPlayingHint;

  /// No description provided for @myPlaytime.
  ///
  /// In en, this message translates to:
  /// **'My playtime'**
  String get myPlaytime;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @lifetimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetimeLabel;

  /// No description provided for @byClubLabel.
  ///
  /// In en, this message translates to:
  /// **'By club'**
  String get byClubLabel;

  /// No description provided for @hoursTiny.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursTiny;

  /// No description provided for @minutesTiny.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesTiny;

  /// No description provided for @noOpenSeats.
  ///
  /// In en, this message translates to:
  /// **'No open seats to reserve right now — join the waitlist instead.'**
  String get noOpenSeats;

  /// No description provided for @openShort.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get openShort;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ka':
      return AppL10nKa();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
