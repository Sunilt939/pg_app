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

  @override
  String gateSignedInAs(String phone) {
    return 'Signed in as $phone';
  }

  @override
  String get gateOwnerTitle => 'I run a PG';

  @override
  String get gateOwnerBody => 'Create your PG and add your guests.';

  @override
  String get gateGuestTitle => 'I\'m a guest';

  @override
  String get gateGuestBody =>
      'Your PG owner adds you using your mobile number.';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get guestWaitBody =>
      'Your number isn\'t registered yet. Please ask your PG owner to add you.';

  @override
  String get yourNumber => 'Your number';

  @override
  String get numberCopied => 'Number copied.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get stillNotAdded =>
      'Still not added. Ask your PG owner to check the number.';

  @override
  String get addPgAbout => 'About your PG';

  @override
  String get addPgName => 'PG name';

  @override
  String get addPgWho => 'Who stays here';

  @override
  String get genderMen => 'Men';

  @override
  String get genderWomen => 'Women';

  @override
  String get genderAny => 'Anyone';

  @override
  String get addPgAddressSection => 'Address';

  @override
  String get addPgAddress => 'Address';

  @override
  String get addPgAddressHint => 'Building, street';

  @override
  String get addPgArea => 'Area (optional)';

  @override
  String get addPgAreaHint => 'Area or locality';

  @override
  String get addPgCity => 'City';

  @override
  String get addPgCityPick => 'Choose a city';

  @override
  String get addPgPincode => 'Pincode (optional)';

  @override
  String get addPgContactSection => 'Contact';

  @override
  String get addPgContact => 'Contact number (optional)';

  @override
  String get addPgContactHelper => 'Guests see this number to contact you.';

  @override
  String get addPgCreate => 'Create PG';

  @override
  String get pgCreated => 'PG created.';

  @override
  String get errPgName => 'Enter the PG name.';

  @override
  String get errPgAddress => 'Enter the address.';

  @override
  String get errPgCity => 'Choose a city.';

  @override
  String get errPincode => 'Enter a 6-digit pincode.';

  @override
  String get switcherTitle => 'Your PGs';

  @override
  String get switcherAdd => 'Add another PG';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCaretaker => 'Caretaker';

  @override
  String get moreYourPg => 'Your PG';

  @override
  String get moreAccount => 'Account';

  @override
  String get moreAbout => 'About';

  @override
  String get moreRooms => 'Rooms and beds';

  @override
  String get moreAccounts => 'Receiving accounts';

  @override
  String get moreReminders => 'Reminders';

  @override
  String get morePgDetails => 'PG details';

  @override
  String get moreProfile => 'Profile';

  @override
  String get moreSwitchGuest => 'Switch to guest view';

  @override
  String get moreAddPg => 'Add another PG';

  @override
  String get moreTerms => 'Terms';

  @override
  String get morePrivacy => 'Privacy Policy';

  @override
  String signOutTitle(String appName) {
    return 'Sign out of $appName?';
  }

  @override
  String get signOutBody =>
      'You will need to sign in again with your phone number to access your account.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get profileNoName => 'Add your name';

  @override
  String get profileDetails => 'Your details';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEmailAdd => 'Add';

  @override
  String get profileMobile => 'Mobile number';

  @override
  String get phoneLocked => 'Your mobile number can\'t be changed here.';

  @override
  String get nameRequired => 'Enter your name.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get actionSave => 'Save';

  @override
  String get profileNameUpdated => 'Name updated';

  @override
  String get profileEmailUpdated => 'Email updated';

  @override
  String get photoTake => 'Take a photo';

  @override
  String get photoChoose => 'Choose from gallery';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get profileDefaultAvatars => 'Choose a default avatar';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoRemoved => 'Profile photo removed';
}
