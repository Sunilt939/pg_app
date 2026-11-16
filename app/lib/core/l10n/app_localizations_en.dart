// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PG App';

  @override
  String get navHome => 'Home';

  @override
  String get navGuests => 'Guests';

  @override
  String get navPayments => 'Payments';

  @override
  String get navMore => 'More';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeTitle => 'Home';

  @override
  String get guestsTitle => 'Guests';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get moreTitle => 'More';

  @override
  String get historyTitle => 'History';

  @override
  String get profileTitle => 'Profile';

  @override
  String get signInTitle => 'Enter your mobile number';

  @override
  String get verifyTitle => 'Enter the 6-digit code';

  @override
  String gateTitle(String appName) {
    return 'How will you use $appName?';
  }

  @override
  String get guestWaitTitle => 'Ask your PG owner to add you';

  @override
  String get addPgTitle => 'Add your PG';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get collectionsTitle => 'Money received';

  @override
  String get roomsTitle => 'Rooms and beds';

  @override
  String get addRoomsTitle => 'Add rooms';

  @override
  String get accountsTitle => 'Receiving accounts';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get pgDetailsTitle => 'PG details';

  @override
  String get payTitle => 'Pay rent';

  @override
  String get addGuestTitle => 'Add guest';

  @override
  String get paymentTitle => 'Payment';
}
