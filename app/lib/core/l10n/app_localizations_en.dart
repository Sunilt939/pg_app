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

  @override
  String get roomFirstNumber => 'First room number';

  @override
  String get roomCount => 'Number of rooms';

  @override
  String get roomBeds => 'Beds in each room';

  @override
  String get roomType => 'Room type (optional)';

  @override
  String get roomTypeNone => 'Not set';

  @override
  String get roomFloor => 'Floor (optional)';

  @override
  String get roomPrefix => 'Number prefix (optional)';

  @override
  String get roomPrefixHint => 'Letters before the number, if any';

  @override
  String roomsPreview(
      int count, String first, String last, int beds, String labels) {
    return 'This will add $count rooms, $first to $last, with $beds beds each ($labels).';
  }

  @override
  String get roomsAddAction => 'Add rooms';

  @override
  String roomsAdded(int count) {
    return '$count rooms added.';
  }

  @override
  String get errRoomNumber => 'Enter the first room number.';

  @override
  String get errRoomCount => 'Enter a number from 1 to 100.';

  @override
  String get actionDone => 'Done';

  @override
  String roomPageTitle(String number) {
    return 'Room $number';
  }

  @override
  String roomsFloor(int floor) {
    return 'Floor $floor';
  }

  @override
  String get layoutTitle => 'Set up rooms';

  @override
  String get layoutMoreRow => 'Set up floors and rooms';

  @override
  String layoutStepLabel(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get layoutNext => 'Next';

  @override
  String get layoutLeaveTitle => 'Leave without saving?';

  @override
  String get layoutLeaveBody => 'The rooms you entered will not be saved.';

  @override
  String get layoutLeaveAction => 'Leave';

  @override
  String get layoutS1Title => 'Start with one floor';

  @override
  String get layoutS1Body =>
      'Set up one floor first. You can copy it to the other floors later in this setup.';

  @override
  String get layoutFloorNumber => 'Floor number';

  @override
  String get layoutFloorHelper => 'Use 0 for the ground floor.';

  @override
  String get layoutRoomCount => 'Rooms on this floor';

  @override
  String layoutS1Preview(int count, String first, String last) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rooms $first to $last.',
      one: 'Room $first.',
    );
    return '$_temp0';
  }

  @override
  String get errLayoutFloor => 'Enter a floor from 0 to 30.';

  @override
  String get errLayoutRooms => 'Enter a number from 1 to 99.';

  @override
  String get layoutS2Title => 'Beds in each room';

  @override
  String get layoutS2Body => 'Change the beds for any room that is different.';

  @override
  String get layoutAllRooms => 'All rooms';

  @override
  String layoutBedsCount(int beds) {
    String _temp0 = intl.Intl.pluralLogic(
      beds,
      locale: localeName,
      other: '$beds beds',
      one: '1 bed',
    );
    return '$_temp0';
  }

  @override
  String layoutFloorTotals(int rooms, int beds) {
    String _temp0 = intl.Intl.pluralLogic(
      rooms,
      locale: localeName,
      other: '$rooms rooms',
      one: '1 room',
    );
    String _temp1 = intl.Intl.pluralLogic(
      beds,
      locale: localeName,
      other: '$beds beds',
      one: '1 bed',
    );
    return '$_temp0, $_temp1 on this floor.';
  }

  @override
  String get bedsFewer => 'Fewer beds';

  @override
  String get bedsMore => 'More beds';

  @override
  String get layoutS3Title => 'How many floors does your PG have?';

  @override
  String get layoutS3Body =>
      'The other floors will copy the first floor. You can change any room before saving.';

  @override
  String get layoutFloorCount => 'Number of floors';

  @override
  String get layoutFloorCountHelper => 'Count the floor you just set up.';

  @override
  String get errLayoutFloors => 'Enter a number from 1 to 30.';

  @override
  String layoutTotals(int floors, int rooms, int beds) {
    String _temp0 = intl.Intl.pluralLogic(
      floors,
      locale: localeName,
      other: '$floors floors',
      one: '1 floor',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rooms,
      locale: localeName,
      other: '$rooms rooms',
      one: '1 room',
    );
    String _temp2 = intl.Intl.pluralLogic(
      beds,
      locale: localeName,
      other: '$beds beds',
      one: '1 bed',
    );
    return '$_temp0, $_temp1, $_temp2';
  }

  @override
  String get layoutS4Title => 'Check your rooms';

  @override
  String get layoutS4Body => 'Tap a room to change it.';

  @override
  String get layoutGroundFloor => 'Ground floor';

  @override
  String get layoutAddRoom => 'Add room';

  @override
  String get layoutSave => 'Save rooms';

  @override
  String get layoutEditTitle => 'Change room';

  @override
  String get layoutNewTitle => 'Add a room';

  @override
  String get layoutRoomNumber => 'Room number';

  @override
  String get layoutBedsLabel => 'Beds';

  @override
  String get layoutRemoveRoom => 'Remove room';

  @override
  String get errLayoutNumber => 'Enter a room number.';

  @override
  String get errLayoutDuplicate => 'This room number is already in the list.';

  @override
  String get errLayoutTooMany => 'You can save up to 500 rooms at a time.';

  @override
  String roomsSummary(int rooms, int beds, int free) {
    String _temp0 = intl.Intl.pluralLogic(
      rooms,
      locale: localeName,
      other: '$rooms rooms',
      one: '1 room',
    );
    String _temp1 = intl.Intl.pluralLogic(
      beds,
      locale: localeName,
      other: '$beds beds',
      one: '1 bed',
    );
    return '$_temp0, $_temp1, $free free';
  }

  @override
  String get roomsNoFloor => 'No floor set';

  @override
  String get roomDefaultTitle => 'Room';

  @override
  String roomsBedsFree(int beds, int free) {
    String _temp0 = intl.Intl.pluralLogic(
      beds,
      locale: localeName,
      other: '$beds beds',
      one: '1 bed',
    );
    return '$_temp0, $free free';
  }

  @override
  String get roomsFull => 'Full';

  @override
  String roomsFreeCount(int free) {
    return '$free free';
  }

  @override
  String get bedFree => 'Free';

  @override
  String get roomsEmptyTitle => 'No rooms yet';

  @override
  String get roomsEmptyBody =>
      'Add your rooms and beds so you can give each guest a bed.';

  @override
  String get roomsEmptyAction => 'Add rooms';

  @override
  String get actionAddGuest => 'Add guest';

  @override
  String get accountsEmptyTitle => 'No receiving accounts yet';

  @override
  String get accountsEmptyBody =>
      'Add the UPI ID or bank account where guests send rent.';

  @override
  String get accountsEmptyAction => 'Add account';

  @override
  String get accountDefault => 'Default';

  @override
  String get accountOff => 'Off';

  @override
  String accountBankEnding(String bank, String last4) {
    return '$bank, ending $last4';
  }

  @override
  String get accountType => 'Type';

  @override
  String get accountTypeUpi => 'UPI';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountNickname => 'Nickname';

  @override
  String get accountUpiId => 'UPI ID';

  @override
  String get accountHolderName => 'Name on the UPI ID (optional)';

  @override
  String get accountHolderHelper => 'Shown to guests when they pay.';

  @override
  String get accountBankName => 'Bank name';

  @override
  String get accountLast4 => 'Last 4 digits of the account (optional)';

  @override
  String get accountBankHolder => 'Account holder name (optional)';

  @override
  String get accountLinkedPhone => 'Linked mobile number (optional)';

  @override
  String get accountUseDefault => 'Use as default';

  @override
  String get accountActive => 'Active';

  @override
  String get accountSave => 'Save account';

  @override
  String get errAccountNickname =>
      'You already have an account with this nickname.';

  @override
  String get errUpiId => 'Enter a valid UPI ID, for example name@bank.';

  @override
  String get errBankName => 'Enter the bank name.';

  @override
  String get errNickname => 'Enter a nickname.';

  @override
  String get addGuestSection => 'Guest';

  @override
  String get addGuestStaySection => 'Stay';

  @override
  String get addGuestMoneySection => 'Rent and deposit';

  @override
  String get guestMobile => 'Mobile number';

  @override
  String get guestMobileHelper =>
      'This number will be used to sign in as a guest.';

  @override
  String get guestName => 'Full name';

  @override
  String get guestBed => 'Bed (optional)';

  @override
  String get guestBedPick => 'Choose a bed';

  @override
  String get guestBedNone => 'No bed yet';

  @override
  String guestBedOption(String room, String bed) {
    return 'Room $room, bed $bed';
  }

  @override
  String get guestJoinDate => 'Joining date';

  @override
  String get guestJoinDatePastNotice =>
      'Joining date is in the past. Turn on Already staying here below if needed.';

  @override
  String get guestRent => 'Monthly rent';

  @override
  String get guestDeposit => 'Security deposit (optional)';

  @override
  String get guestBillingDay => 'Rent is due on day';

  @override
  String get billingDayHelper => 'Due every month on this day.';

  @override
  String get alreadyStaying => 'Already staying here';

  @override
  String get alreadyStayingHelper =>
      'Turn on for guests who joined before you started using the app.';

  @override
  String get billingStartsFrom => 'Start billing from';

  @override
  String get billingStartHelper =>
      'Rent due before this date won\'t be billed.';

  @override
  String get depositReceived => 'Deposit already received';

  @override
  String get depositReceivedHelper => 'The deposit will not show as due.';

  @override
  String get addGuestAction => 'Add guest';

  @override
  String get inviteTitle => 'Guest added';

  @override
  String inviteBody(String name, String phone) {
    return 'Ask $name to sign in with $phone.';
  }

  @override
  String get inviteAction => 'Invite on WhatsApp';

  @override
  String inviteMessage(String name, String pg, String appName) {
    return 'Hi $name, I\'ve added you to $pg on $appName. Download the app and sign in with this mobile number.';
  }

  @override
  String get errGuestExists => 'This guest is already staying in this PG.';

  @override
  String get errBedTaken => 'That bed was just taken. Choose another.';

  @override
  String get errGuestName => 'Enter the guest\'s name.';

  @override
  String get errRent => 'Enter the monthly rent.';

  @override
  String get errorNotAllowed => 'You do not have permission to do this.';

  @override
  String get guestSearchHint => 'Search name, room or number';

  @override
  String get tabAll => 'All';

  @override
  String get tabOverdue => 'Overdue';

  @override
  String get tabDue => 'Due';

  @override
  String get tabPaid => 'Paid';

  @override
  String get tabPast => 'Past';

  @override
  String get guestNoBed => 'No bed yet';

  @override
  String guestBedPart(String bed) {
    return 'Bed $bed';
  }

  @override
  String guestStateOverdue(String date) {
    return 'overdue since $date';
  }

  @override
  String get guestStatePending => 'payment waiting for you';

  @override
  String guestStateDue(String date) {
    return 'due $date';
  }

  @override
  String get guestStatePaid => 'paid up';

  @override
  String guestStatePaidAdvance(String amount) {
    return 'paid up, advance $amount';
  }

  @override
  String guestLeft(String date) {
    return 'Left $date';
  }

  @override
  String get guestsEmptyTitle => 'No guests yet';

  @override
  String get guestsEmptyBody => 'Add your first guest to start tracking rent.';

  @override
  String get guestsFilterEmptyTitle => 'No guests here';

  @override
  String get guestsFilterEmptyBody => 'Nothing matches this filter.';

  @override
  String guestDetailStayEnded(String room, String bed, String from, String to) {
    return 'Room $room, bed $bed, $from to $to';
  }

  @override
  String guestDetailStay(String room, String bed, String date) {
    return 'Room $room, bed $bed, since $date';
  }

  @override
  String guestDetailStayNoBed(String date) {
    return 'since $date';
  }

  @override
  String guestDetailStayNoBedEnded(String from, String to) {
    return '$from to $to';
  }

  @override
  String get balanceOutstanding => 'Outstanding';

  @override
  String get balanceCharged => 'Charged';

  @override
  String get balancePaid => 'Paid';

  @override
  String get balanceAdvance => 'Advance';

  @override
  String balanceWaiting(String amount) {
    return '$amount reported by the guest, waiting for you.';
  }

  @override
  String get waitingForYou => 'Waiting for you';

  @override
  String get detailCharges => 'Charges';

  @override
  String get detailPayments => 'Payments';

  @override
  String get detailDetails => 'Details';

  @override
  String get detailApp => 'App';

  @override
  String get detailAppSignedIn => 'Signed in';

  @override
  String get detailAppNotYet => 'Not signed in yet';

  @override
  String get detailInviteAgain => 'Invite again';

  @override
  String get detailEmergency => 'Emergency contact';

  @override
  String get detailDocuments => 'ID documents';

  @override
  String detailDocumentsCount(int count) {
    return '$count uploaded';
  }

  @override
  String get detailNone => 'None';

  @override
  String profileDueDay(String day) {
    return 'Day $day of every month';
  }

  @override
  String chargeDue(String date) {
    return 'due $date';
  }

  @override
  String get chargePartPaid => 'Part-paid';

  @override
  String get chargeCancelled => 'Cancelled';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusReversed => 'Reversed';

  @override
  String get detailSeeAll => 'See all';

  @override
  String get allChargesTitle => 'All charges';

  @override
  String get allPaymentsTitle => 'All payments';
}
