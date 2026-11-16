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

  @override
  String get signInHeadline => 'Your PG, in order.';

  @override
  String get signInSubline => 'Rent, receipts and reminders in one place.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '10-digit mobile number';

  @override
  String get phoneHelper => 'We\'ll send a 6-digit code by SMS.';

  @override
  String get phoneInvalid => 'Enter a valid 10-digit mobile number.';

  @override
  String get sendCode => 'Send code';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String termsLine(String terms, String privacy) {
    return 'By continuing you agree to the $terms and $privacy.';
  }

  @override
  String get termsLink => 'Terms';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String verifySentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get verifyChangeNumber => 'Change number';

  @override
  String get verifyAction => 'Verify';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendAction => 'Resend code';

  @override
  String get codeSent => 'Code sent.';

  @override
  String get otpInvalid =>
      'That code isn\'t right. Check the SMS and try again.';

  @override
  String get otpExpired => 'That code has expired. Request a new one.';
}
