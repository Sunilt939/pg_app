import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The name of the app
  ///
  /// In en, this message translates to:
  /// **'PG App'**
  String get appName;

  /// Bottom navigation label for Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for Guests tab
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get navGuests;

  /// Bottom navigation label for Payments tab
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// Bottom navigation label for More tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Bottom navigation label for History tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom navigation label for Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Title for Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Title for Guests screen
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsTitle;

  /// Title for Payments screen
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// Title for More screen
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// Title for History screen
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Title for Profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Title for Sign In screen
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get signInTitle;

  /// Title for Verify OTP screen
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get verifyTitle;

  /// Title for Role Gate screen
  ///
  /// In en, this message translates to:
  /// **'How will you use {appName}?'**
  String gateTitle(String appName);

  /// Title for Gate Guest waiting screen
  ///
  /// In en, this message translates to:
  /// **'Ask your PG owner to add you'**
  String get guestWaitTitle;

  /// Title for Add PG screen
  ///
  /// In en, this message translates to:
  /// **'Add your PG'**
  String get addPgTitle;

  /// Title for Receipt screen
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// Title for Notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Title for Collections screen
  ///
  /// In en, this message translates to:
  /// **'Money received'**
  String get collectionsTitle;

  /// Title for Rooms screen
  ///
  /// In en, this message translates to:
  /// **'Rooms and beds'**
  String get roomsTitle;

  /// Title for Add Rooms screen
  ///
  /// In en, this message translates to:
  /// **'Add rooms'**
  String get addRoomsTitle;

  /// Title for Receiving Accounts screen
  ///
  /// In en, this message translates to:
  /// **'Receiving accounts'**
  String get accountsTitle;

  /// Title for Reminders screen
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// Title for PG Details screen
  ///
  /// In en, this message translates to:
  /// **'PG details'**
  String get pgDetailsTitle;

  /// Title for Pay Rent screen
  ///
  /// In en, this message translates to:
  /// **'Pay rent'**
  String get payTitle;

  /// Title for Add Guest screen
  ///
  /// In en, this message translates to:
  /// **'Add guest'**
  String get addGuestTitle;

  /// Title for Payment detail screen
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
