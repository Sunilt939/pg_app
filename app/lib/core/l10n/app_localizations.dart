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

  /// Headline on the sign in screen photo area
  ///
  /// In en, this message translates to:
  /// **'Your PG, in order.'**
  String get signInHeadline;

  /// Subline on the sign in screen photo area
  ///
  /// In en, this message translates to:
  /// **'Rent, receipts and reminders in one place.'**
  String get signInSubline;

  /// Label for mobile number field
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// Hint for mobile number field
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get phoneHint;

  /// Helper text under mobile number field
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit code by SMS.'**
  String get phoneHelper;

  /// Error text for invalid mobile number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get phoneInvalid;

  /// Action button text to send OTP code
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Error text when rate limit is exceeded
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get tooManyAttempts;

  /// Terms and conditions line
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the {terms} and {privacy}.'**
  String termsLine(String terms, String privacy);

  /// Terms link text
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLink;

  /// Network connection error message
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Phone number OTP was sent to
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String verifySentTo(String phone);

  /// Button to change mobile number
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get verifyChangeNumber;

  /// Button text to verify OTP
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// Resend countdown message
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendIn(String time);

  /// Action button text to resend OTP
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendAction;

  /// Snackbar message when new code is sent
  ///
  /// In en, this message translates to:
  /// **'Code sent.'**
  String get codeSent;

  /// Error message for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the SMS and try again.'**
  String get otpInvalid;

  /// Error message for expired OTP
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Request a new one.'**
  String get otpExpired;

  /// Subtitle showing signed-in phone number on role gate
  ///
  /// In en, this message translates to:
  /// **'Signed in as {phone}'**
  String gateSignedInAs(String phone);

  /// Option title for owner on role gate
  ///
  /// In en, this message translates to:
  /// **'I run a PG'**
  String get gateOwnerTitle;

  /// Option description for owner on role gate
  ///
  /// In en, this message translates to:
  /// **'Create your PG and add your guests.'**
  String get gateOwnerBody;

  /// Option title for guest on role gate
  ///
  /// In en, this message translates to:
  /// **'I\'m a guest'**
  String get gateGuestTitle;

  /// Option description for guest on role gate
  ///
  /// In en, this message translates to:
  /// **'Your PG owner adds you using your mobile number.'**
  String get gateGuestBody;

  /// Action button text to sign out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// Description on gate guest waiting screen
  ///
  /// In en, this message translates to:
  /// **'Your number isn\'t registered yet. Please ask your PG owner to add you.'**
  String get guestWaitBody;

  /// Label for your number
  ///
  /// In en, this message translates to:
  /// **'Your number'**
  String get yourNumber;

  /// Feedback when number is copied
  ///
  /// In en, this message translates to:
  /// **'Number copied.'**
  String get numberCopied;

  /// Action button to check status again
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// Error message when still not added to a PG
  ///
  /// In en, this message translates to:
  /// **'Still not added. Ask your PG owner to check the number.'**
  String get stillNotAdded;

  /// Section header for About your PG
  ///
  /// In en, this message translates to:
  /// **'About your PG'**
  String get addPgAbout;

  /// Label for PG name field
  ///
  /// In en, this message translates to:
  /// **'PG name'**
  String get addPgName;

  /// Label for gender policy selection
  ///
  /// In en, this message translates to:
  /// **'Who stays here'**
  String get addPgWho;

  /// Option for men only PG
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get genderMen;

  /// Option for women only PG
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get genderWomen;

  /// Option for co-ed / anyone PG
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get genderAny;

  /// Section header for PG address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addPgAddressSection;

  /// Label for address line 1 field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addPgAddress;

  /// Hint for address field
  ///
  /// In en, this message translates to:
  /// **'Building, street'**
  String get addPgAddressHint;

  /// Label for area field
  ///
  /// In en, this message translates to:
  /// **'Area (optional)'**
  String get addPgArea;

  /// Hint for area field
  ///
  /// In en, this message translates to:
  /// **'Area or locality'**
  String get addPgAreaHint;

  /// Label for city selection field
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addPgCity;

  /// Title and hint for choosing city
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get addPgCityPick;

  /// Label for pincode field
  ///
  /// In en, this message translates to:
  /// **'Pincode (optional)'**
  String get addPgPincode;

  /// Section header for contact info
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get addPgContactSection;

  /// Label for contact phone field
  ///
  /// In en, this message translates to:
  /// **'Contact number (optional)'**
  String get addPgContact;

  /// Helper text for contact phone
  ///
  /// In en, this message translates to:
  /// **'Guests see this number to contact you.'**
  String get addPgContactHelper;

  /// Button to create PG
  ///
  /// In en, this message translates to:
  /// **'Create PG'**
  String get addPgCreate;

  /// Snackbar when PG is created
  ///
  /// In en, this message translates to:
  /// **'PG created.'**
  String get pgCreated;

  /// Validation error for PG name
  ///
  /// In en, this message translates to:
  /// **'Enter the PG name.'**
  String get errPgName;

  /// Validation error for PG address
  ///
  /// In en, this message translates to:
  /// **'Enter the address.'**
  String get errPgAddress;

  /// Validation error for PG city
  ///
  /// In en, this message translates to:
  /// **'Choose a city.'**
  String get errPgCity;

  /// Validation error for pincode
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit pincode.'**
  String get errPincode;

  /// Title for PG switcher bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Your PGs'**
  String get switcherTitle;

  /// Action to add another PG
  ///
  /// In en, this message translates to:
  /// **'Add another PG'**
  String get switcherAdd;

  /// Role label for owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// Role label for manager
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// Role label for caretaker
  ///
  /// In en, this message translates to:
  /// **'Caretaker'**
  String get roleCaretaker;

  /// Section header for Your PG on More screen
  ///
  /// In en, this message translates to:
  /// **'Your PG'**
  String get moreYourPg;

  /// Section header for Account on More screen
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get moreAccount;

  /// Section header for About on More screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get moreAbout;

  /// Label for rooms and beds row
  ///
  /// In en, this message translates to:
  /// **'Rooms and beds'**
  String get moreRooms;

  /// Label for receiving accounts row
  ///
  /// In en, this message translates to:
  /// **'Receiving accounts'**
  String get moreAccounts;

  /// Label for reminders row
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get moreReminders;

  /// Label for PG details row
  ///
  /// In en, this message translates to:
  /// **'PG details'**
  String get morePgDetails;

  /// Label for profile row
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get moreProfile;

  /// Label for switch to guest view row
  ///
  /// In en, this message translates to:
  /// **'Switch to guest view'**
  String get moreSwitchGuest;

  /// Label for add another PG row
  ///
  /// In en, this message translates to:
  /// **'Add another PG'**
  String get moreAddPg;

  /// Label for terms row
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get moreTerms;

  /// Label for privacy policy row
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get morePrivacy;

  /// Title for sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out of {appName}?'**
  String signOutTitle(String appName);

  /// Body message for sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again with your phone number to access your account.'**
  String get signOutBody;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Placeholder when person has no name in profile
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get profileNoName;

  /// Section header for Your details in profile
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get profileDetails;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// Label for adding email when missing
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileEmailAdd;

  /// Label for mobile number field
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profileMobile;

  /// Snackbar message when tapping locked phone number
  ///
  /// In en, this message translates to:
  /// **'Your mobile number can\'t be changed here.'**
  String get phoneLocked;

  /// Validation error when name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get nameRequired;

  /// Validation error when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Snackbar message when name is successfully updated
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get profileNameUpdated;

  /// Snackbar message when email is successfully updated
  ///
  /// In en, this message translates to:
  /// **'Email updated'**
  String get profileEmailUpdated;

  /// Option to take a profile photo with camera
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoTake;

  /// Option to choose a profile photo from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoChoose;

  /// Option to remove custom profile photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// Title for profile photo options bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoTitle;

  /// Header for default avatars in profile photo sheet
  ///
  /// In en, this message translates to:
  /// **'Choose a default avatar'**
  String get profileDefaultAvatars;

  /// Snackbar message when profile photo or avatar is updated
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// Snackbar message when profile photo is removed
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get profilePhotoRemoved;

  /// Label for first room number input
  ///
  /// In en, this message translates to:
  /// **'First room number'**
  String get roomFirstNumber;

  /// Label for number of rooms input
  ///
  /// In en, this message translates to:
  /// **'Number of rooms'**
  String get roomCount;

  /// Label for beds in each room input
  ///
  /// In en, this message translates to:
  /// **'Beds in each room'**
  String get roomBeds;

  /// Label for room type selection
  ///
  /// In en, this message translates to:
  /// **'Room type (optional)'**
  String get roomType;

  /// Label for no room type option
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get roomTypeNone;

  /// Label for floor input
  ///
  /// In en, this message translates to:
  /// **'Floor (optional)'**
  String get roomFloor;

  /// Label for room number prefix input
  ///
  /// In en, this message translates to:
  /// **'Number prefix (optional)'**
  String get roomPrefix;

  /// Hint text for room number prefix input
  ///
  /// In en, this message translates to:
  /// **'Letters before the number, if any'**
  String get roomPrefixHint;

  /// Preview summary line for bulk room creation
  ///
  /// In en, this message translates to:
  /// **'This will add {count} rooms, {first} to {last}, with {beds} beds each ({labels}).'**
  String roomsPreview(
      int count, String first, String last, int beds, String labels);

  /// Button text to add rooms
  ///
  /// In en, this message translates to:
  /// **'Add rooms'**
  String get roomsAddAction;

  /// Snackbar message when rooms are added successfully
  ///
  /// In en, this message translates to:
  /// **'{count} rooms added.'**
  String roomsAdded(int count);

  /// Error message when first room number is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the first room number.'**
  String get errRoomNumber;

  /// Error message when room count is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 100.'**
  String get errRoomCount;

  /// Button text for Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Title showing room number
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String roomPageTitle(String number);

  /// Header showing floor number
  ///
  /// In en, this message translates to:
  /// **'Floor {floor}'**
  String roomsFloor(int floor);

  /// Screen title for room layout setup
  ///
  /// In en, this message translates to:
  /// **'Set up rooms'**
  String get layoutTitle;

  /// Row label in More tab to open floor setup
  ///
  /// In en, this message translates to:
  /// **'Set up floors and rooms'**
  String get layoutMoreRow;

  /// Current step in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String layoutStepLabel(int step, int total);

  /// Button to go to the next setup step
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get layoutNext;

  /// Confirm sheet title when leaving setup
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get layoutLeaveTitle;

  /// Confirm sheet message when leaving setup
  ///
  /// In en, this message translates to:
  /// **'The rooms you entered will not be saved.'**
  String get layoutLeaveBody;

  /// Destructive button to leave setup
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get layoutLeaveAction;

  /// Title of step 1 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Start with one floor'**
  String get layoutS1Title;

  /// Description of step 1 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Set up one floor first. You can copy it to the other floors later in this setup.'**
  String get layoutS1Body;

  /// Input label for initial floor number
  ///
  /// In en, this message translates to:
  /// **'Floor number'**
  String get layoutFloorNumber;

  /// Helper text for floor number input
  ///
  /// In en, this message translates to:
  /// **'Use 0 for the ground floor.'**
  String get layoutFloorHelper;

  /// Input label for rooms count on the floor
  ///
  /// In en, this message translates to:
  /// **'Rooms on this floor'**
  String get layoutRoomCount;

  /// Live preview line for step 1
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Room {first}.} other{Rooms {first} to {last}.}}'**
  String layoutS1Preview(int count, String first, String last);

  /// Validation error for floor number
  ///
  /// In en, this message translates to:
  /// **'Enter a floor from 0 to 30.'**
  String get errLayoutFloor;

  /// Validation error for room count on floor
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 99.'**
  String get errLayoutRooms;

  /// Title of step 2 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Beds in each room'**
  String get layoutS2Title;

  /// Description of step 2 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Change the beds for any room that is different.'**
  String get layoutS2Body;

  /// Label for master bed stepper setting all rooms
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get layoutAllRooms;

  /// Pluralized beds count label
  ///
  /// In en, this message translates to:
  /// **'{beds, plural, =1{1 bed} other{{beds} beds}}'**
  String layoutBedsCount(int beds);

  /// Summary total for current floor in step 2
  ///
  /// In en, this message translates to:
  /// **'{rooms, plural, =1{1 room} other{{rooms} rooms}}, {beds, plural, =1{1 bed} other{{beds} beds}} on this floor.'**
  String layoutFloorTotals(int rooms, int beds);

  /// Accessibility tooltip for decrementing beds
  ///
  /// In en, this message translates to:
  /// **'Fewer beds'**
  String get bedsFewer;

  /// Accessibility tooltip for incrementing beds
  ///
  /// In en, this message translates to:
  /// **'More beds'**
  String get bedsMore;

  /// Title of step 3 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'How many floors does your PG have?'**
  String get layoutS3Title;

  /// Description of step 3 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'The other floors will copy the first floor. You can change any room before saving.'**
  String get layoutS3Body;

  /// Input label for total floors in PG
  ///
  /// In en, this message translates to:
  /// **'Number of floors'**
  String get layoutFloorCount;

  /// Helper text for total floors input
  ///
  /// In en, this message translates to:
  /// **'Count the floor you just set up.'**
  String get layoutFloorCountHelper;

  /// Validation error for total floor count
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 30.'**
  String get errLayoutFloors;

  /// Overall total floors, rooms, and beds summary
  ///
  /// In en, this message translates to:
  /// **'{floors, plural, =1{1 floor} other{{floors} floors}}, {rooms, plural, =1{1 room} other{{rooms} rooms}}, {beds, plural, =1{1 bed} other{{beds} beds}}'**
  String layoutTotals(int floors, int rooms, int beds);

  /// Title of step 4 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Check your rooms'**
  String get layoutS4Title;

  /// Description of step 4 in setup wizard
  ///
  /// In en, this message translates to:
  /// **'Tap a room to change it.'**
  String get layoutS4Body;

  /// Section header for ground floor (floor 0)
  ///
  /// In en, this message translates to:
  /// **'Ground floor'**
  String get layoutGroundFloor;

  /// Button to add a room to a floor in step 4
  ///
  /// In en, this message translates to:
  /// **'Add room'**
  String get layoutAddRoom;

  /// Primary action button to save layout in step 4
  ///
  /// In en, this message translates to:
  /// **'Save rooms'**
  String get layoutSave;

  /// Sheet title for editing a room in step 4
  ///
  /// In en, this message translates to:
  /// **'Change room'**
  String get layoutEditTitle;

  /// Sheet title for adding a room in step 4
  ///
  /// In en, this message translates to:
  /// **'Add a room'**
  String get layoutNewTitle;

  /// Input label for room number in edit/add sheet
  ///
  /// In en, this message translates to:
  /// **'Room number'**
  String get layoutRoomNumber;

  /// Label for beds stepper in room edit sheet
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get layoutBedsLabel;

  /// Button to delete room from layout
  ///
  /// In en, this message translates to:
  /// **'Remove room'**
  String get layoutRemoveRoom;

  /// Validation error when room number is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a room number.'**
  String get errLayoutNumber;

  /// Validation error when room number duplicates another in layout
  ///
  /// In en, this message translates to:
  /// **'This room number is already in the list.'**
  String get errLayoutDuplicate;

  /// Validation error when total rooms exceeds 500
  ///
  /// In en, this message translates to:
  /// **'You can save up to 500 rooms at a time.'**
  String get errLayoutTooMany;

  /// Summary count of rooms, beds, and free beds in rooms list
  ///
  /// In en, this message translates to:
  /// **'{rooms, plural, =1{1 room} other{{rooms} rooms}}, {beds, plural, =1{1 bed} other{{beds} beds}}, {free} free'**
  String roomsSummary(int rooms, int beds, int free);

  /// Section header for rooms without a floor assigned
  ///
  /// In en, this message translates to:
  /// **'No floor set'**
  String get roomsNoFloor;

  /// Default room item title when room type is not set
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomDefaultTitle;

  /// Subtitle showing beds count and free beds count for a room
  ///
  /// In en, this message translates to:
  /// **'{beds, plural, =1{1 bed} other{{beds} beds}}, {free} free'**
  String roomsBedsFree(int beds, int free);

  /// Trailing label when a room has 0 free beds
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get roomsFull;

  /// Trailing label showing free bed count in a room
  ///
  /// In en, this message translates to:
  /// **'{free} free'**
  String roomsFreeCount(int free);

  /// Title label for an unoccupied bed on the room detail page
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get bedFree;

  /// Empty state title when PG has no rooms
  ///
  /// In en, this message translates to:
  /// **'No rooms yet'**
  String get roomsEmptyTitle;

  /// Empty state body description when PG has no rooms
  ///
  /// In en, this message translates to:
  /// **'Add your rooms and beds so you can give each guest a bed.'**
  String get roomsEmptyBody;

  /// Button to add rooms from empty state
  ///
  /// In en, this message translates to:
  /// **'Add rooms'**
  String get roomsEmptyAction;

  /// Action button to add a guest to a free bed
  ///
  /// In en, this message translates to:
  /// **'Add guest'**
  String get actionAddGuest;

  /// Empty state title when PG has no receiving accounts
  ///
  /// In en, this message translates to:
  /// **'No receiving accounts yet'**
  String get accountsEmptyTitle;

  /// Empty state body when PG has no receiving accounts
  ///
  /// In en, this message translates to:
  /// **'Add the UPI ID or bank account where guests send rent.'**
  String get accountsEmptyBody;

  /// Button to add an account from empty state
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsEmptyAction;

  /// Chip label for default receiving account
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accountDefault;

  /// Chip label for inactive receiving account
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get accountOff;

  /// Subtitle for bank account with last 4 digits
  ///
  /// In en, this message translates to:
  /// **'{bank}, ending {last4}'**
  String accountBankEnding(String bank, String last4);

  /// Label for account type selection
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountType;

  /// UPI account type option
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get accountTypeUpi;

  /// Bank account type option
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// Label for account nickname field
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get accountNickname;

  /// Label for UPI ID field
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get accountUpiId;

  /// Label for UPI account holder name field
  ///
  /// In en, this message translates to:
  /// **'Name on the UPI ID (optional)'**
  String get accountHolderName;

  /// Helper text for UPI account holder name field
  ///
  /// In en, this message translates to:
  /// **'Shown to guests when they pay.'**
  String get accountHolderHelper;

  /// Label for bank name field
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get accountBankName;

  /// Label for last 4 digits of bank account
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits of the account (optional)'**
  String get accountLast4;

  /// Label for bank account holder name field
  ///
  /// In en, this message translates to:
  /// **'Account holder name (optional)'**
  String get accountBankHolder;

  /// Label for linked mobile phone field
  ///
  /// In en, this message translates to:
  /// **'Linked mobile number (optional)'**
  String get accountLinkedPhone;

  /// Switch label to make account default
  ///
  /// In en, this message translates to:
  /// **'Use as default'**
  String get accountUseDefault;

  /// Switch label to activate/deactivate account in edit mode
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountActive;

  /// Button to save receiving account
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get accountSave;

  /// Validation error for duplicate nickname
  ///
  /// In en, this message translates to:
  /// **'You already have an account with this nickname.'**
  String get errAccountNickname;

  /// Validation error for invalid UPI ID
  ///
  /// In en, this message translates to:
  /// **'Enter a valid UPI ID, for example name@bank.'**
  String get errUpiId;

  /// Validation error when bank name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the bank name.'**
  String get errBankName;

  /// Validation error when nickname is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname.'**
  String get errNickname;

  /// Section header for guest details in Add Guest
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get addGuestSection;

  /// Section header for stay details in Add Guest
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get addGuestStaySection;

  /// Section header for rent and deposit in Add Guest
  ///
  /// In en, this message translates to:
  /// **'Rent and deposit'**
  String get addGuestMoneySection;

  /// Label for mobile number field
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get guestMobile;

  /// Helper text under mobile number field
  ///
  /// In en, this message translates to:
  /// **'This number will be used to sign in as a guest.'**
  String get guestMobileHelper;

  /// Label for full name field
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get guestName;

  /// Label for bed selection field
  ///
  /// In en, this message translates to:
  /// **'Bed (optional)'**
  String get guestBed;

  /// Hint text for picking a bed
  ///
  /// In en, this message translates to:
  /// **'Choose a bed'**
  String get guestBedPick;

  /// Option when no bed is assigned yet
  ///
  /// In en, this message translates to:
  /// **'No bed yet'**
  String get guestBedNone;

  /// Bed option display
  ///
  /// In en, this message translates to:
  /// **'Room {room}, bed {bed}'**
  String guestBedOption(String room, String bed);

  /// Label for joining date field
  ///
  /// In en, this message translates to:
  /// **'Joining date'**
  String get guestJoinDate;

  /// Helper notice under joining date when selected date is in the past
  ///
  /// In en, this message translates to:
  /// **'Joining date is in the past. Turn on Already staying here below if needed.'**
  String get guestJoinDatePastNotice;

  /// Label for monthly rent field
  ///
  /// In en, this message translates to:
  /// **'Monthly rent'**
  String get guestRent;

  /// Label for security deposit field
  ///
  /// In en, this message translates to:
  /// **'Security deposit (optional)'**
  String get guestDeposit;

  /// Label for rent due day field
  ///
  /// In en, this message translates to:
  /// **'Rent is due on day'**
  String get guestBillingDay;

  /// Helper text under billing day field
  ///
  /// In en, this message translates to:
  /// **'Due every month on this day.'**
  String get billingDayHelper;

  /// Switch label for guests who joined earlier
  ///
  /// In en, this message translates to:
  /// **'Already staying here'**
  String get alreadyStaying;

  /// Helper text for already staying switch
  ///
  /// In en, this message translates to:
  /// **'Turn on for guests who joined before you started using the app.'**
  String get alreadyStayingHelper;

  /// Label for start billing date field
  ///
  /// In en, this message translates to:
  /// **'Start billing from'**
  String get billingStartsFrom;

  /// Helper text under billing start date field
  ///
  /// In en, this message translates to:
  /// **'Rent due before this date won\'t be billed.'**
  String get billingStartHelper;

  /// Switch label for deposit already received
  ///
  /// In en, this message translates to:
  /// **'Deposit already received'**
  String get depositReceived;

  /// Helper text under deposit received switch
  ///
  /// In en, this message translates to:
  /// **'The deposit will not show as due.'**
  String get depositReceivedHelper;

  /// Submit button label for adding a guest
  ///
  /// In en, this message translates to:
  /// **'Add guest'**
  String get addGuestAction;

  /// Title for invite bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Guest added'**
  String get inviteTitle;

  /// Body message for invite bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Ask {name} to sign in with {phone}.'**
  String inviteBody(String name, String phone);

  /// Action button to share invite on WhatsApp
  ///
  /// In en, this message translates to:
  /// **'Invite on WhatsApp'**
  String get inviteAction;

  /// WhatsApp invitation message
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, I\'ve added you to {pg} on {appName}. Download the app and sign in with this mobile number.'**
  String inviteMessage(String name, String pg, String appName);

  /// Error when guest already has an active stay in this PG
  ///
  /// In en, this message translates to:
  /// **'This guest is already staying in this PG.'**
  String get errGuestExists;

  /// Error when bed has just been occupied
  ///
  /// In en, this message translates to:
  /// **'That bed was just taken. Choose another.'**
  String get errBedTaken;

  /// Validation error when full name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the guest\'s name.'**
  String get errGuestName;

  /// Validation error when monthly rent is missing or zero
  ///
  /// In en, this message translates to:
  /// **'Enter the monthly rent.'**
  String get errRent;

  /// Error text when user lacks permission (SQLSTATE 42501)
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do this.'**
  String get errorNotAllowed;

  /// Hint for guest search field
  ///
  /// In en, this message translates to:
  /// **'Search name, room or number'**
  String get guestSearchHint;

  /// Tab label for All guests
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// Tab label for Overdue guests
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tabOverdue;

  /// Tab label for Due guests
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get tabDue;

  /// Tab label for Paid guests
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get tabPaid;

  /// Tab label for Past guests
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tabPast;

  /// Subtitle part when guest has no assigned bed
  ///
  /// In en, this message translates to:
  /// **'No bed yet'**
  String get guestNoBed;

  /// Subtitle part showing guest bed
  ///
  /// In en, this message translates to:
  /// **'Bed {bed}'**
  String guestBedPart(String bed);

  /// Subtitle state part when overdue
  ///
  /// In en, this message translates to:
  /// **'overdue since {date}'**
  String guestStateOverdue(String date);

  /// Subtitle state part when payment is waiting verification
  ///
  /// In en, this message translates to:
  /// **'payment waiting for you'**
  String get guestStatePending;

  /// Subtitle state part when rent is due
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String guestStateDue(String date);

  /// Subtitle state part when rent is paid
  ///
  /// In en, this message translates to:
  /// **'paid up'**
  String get guestStatePaid;

  /// Subtitle state part when rent is paid and has advance/credit
  ///
  /// In en, this message translates to:
  /// **'paid up, advance {amount}'**
  String guestStatePaidAdvance(String amount);

  /// Subtitle for past guest showing departure date
  ///
  /// In en, this message translates to:
  /// **'Left {date}'**
  String guestLeft(String date);

  /// Empty state title when PG has no guests
  ///
  /// In en, this message translates to:
  /// **'No guests yet'**
  String get guestsEmptyTitle;

  /// Empty state body when PG has no guests
  ///
  /// In en, this message translates to:
  /// **'Add your first guest to start tracking rent.'**
  String get guestsEmptyBody;

  /// Empty state title when no guests match tab filter or search
  ///
  /// In en, this message translates to:
  /// **'No guests here'**
  String get guestsFilterEmptyTitle;

  /// Empty state body when no guests match tab filter or search
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter.'**
  String get guestsFilterEmptyBody;

  /// Stay subtitle for vacated guest with bed and room
  ///
  /// In en, this message translates to:
  /// **'Room {room}, bed {bed}, {from} to {to}'**
  String guestDetailStayEnded(String room, String bed, String from, String to);

  /// Stay subtitle for open guest with bed and room
  ///
  /// In en, this message translates to:
  /// **'Room {room}, bed {bed}, since {date}'**
  String guestDetailStay(String room, String bed, String date);

  /// Stay subtitle for open guest without assigned bed
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String guestDetailStayNoBed(String date);

  /// Stay subtitle for vacated guest without assigned bed
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String guestDetailStayNoBedEnded(String from, String to);

  /// Label for outstanding balance in guest detail
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get balanceOutstanding;

  /// Label for total charged amount in guest detail
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get balanceCharged;

  /// Label for total paid amount in guest detail
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get balancePaid;

  /// Label for advance/credit balance in guest detail
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get balanceAdvance;

  /// Notice when pending verification payments exist
  ///
  /// In en, this message translates to:
  /// **'{amount} reported by the guest, waiting for you.'**
  String balanceWaiting(String amount);

  /// Section header for pending payments waiting verification
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get waitingForYou;

  /// Section header for charges list in guest detail
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get detailCharges;

  /// Section header for payments list in guest detail
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get detailPayments;

  /// Section header for details sheet in guest detail
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailDetails;

  /// Label for guest app status row
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get detailApp;

  /// Value when guest has signed in
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get detailAppSignedIn;

  /// Value when guest has not signed in
  ///
  /// In en, this message translates to:
  /// **'Not signed in yet'**
  String get detailAppNotYet;

  /// Action button to share invite with guest again
  ///
  /// In en, this message translates to:
  /// **'Invite again'**
  String get detailInviteAgain;

  /// Label for emergency contact row
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get detailEmergency;

  /// Label for ID documents row
  ///
  /// In en, this message translates to:
  /// **'ID documents'**
  String get detailDocuments;

  /// Document count label
  ///
  /// In en, this message translates to:
  /// **'{count} uploaded'**
  String detailDocumentsCount(int count);

  /// Placeholder when no emergency contact or documents exist
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get detailNone;

  /// Recurring billing day description
  ///
  /// In en, this message translates to:
  /// **'Day {day} of every month'**
  String profileDueDay(String day);

  /// Due date label for charge row
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String chargeDue(String date);

  /// Status chip label for partially paid charge
  ///
  /// In en, this message translates to:
  /// **'Part-paid'**
  String get chargePartPaid;

  /// Status chip label for voided charge
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get chargeCancelled;

  /// Status chip label for rejected payment
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// Status chip label for reversed payment
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get statusReversed;

  /// Action label to see all charges or payments
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get detailSeeAll;

  /// Screen title for all charges list
  ///
  /// In en, this message translates to:
  /// **'All charges'**
  String get allChargesTitle;

  /// Screen title for all payments list
  ///
  /// In en, this message translates to:
  /// **'All payments'**
  String get allPaymentsTitle;

  /// Action row and sheet title for changing stay rent
  ///
  /// In en, this message translates to:
  /// **'Change rent'**
  String get actionChangeRent;

  /// Label for new monthly rent field
  ///
  /// In en, this message translates to:
  /// **'New monthly rent'**
  String get rentNew;

  /// Label for starting date field when changing rent
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get rentFrom;

  /// Helper text explaining rent change effect on existing charges
  ///
  /// In en, this message translates to:
  /// **'Charges that already exist keep the old rent.'**
  String get rentChangeHelper;

  /// Primary action button label to submit rent change
  ///
  /// In en, this message translates to:
  /// **'Change rent'**
  String get rentChangeAction;

  /// Snackbar message when rent change succeeds
  ///
  /// In en, this message translates to:
  /// **'Rent changed.'**
  String get rentChanged;

  /// Error message when a rent term already exists on the selected date
  ///
  /// In en, this message translates to:
  /// **'A rent change already exists from that date. Pick another date.'**
  String get errRentDate;

  /// Action row and sheet title for adding a charge
  ///
  /// In en, this message translates to:
  /// **'Add a charge'**
  String get actionAddCharge;

  /// Label for charge type selection field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chargeType;

  /// Label for charge amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get chargeAmount;

  /// Label for charge due date field
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get chargeDueDate;

  /// Label for optional charge note field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get chargeNote;

  /// Primary action button label to submit new charge
  ///
  /// In en, this message translates to:
  /// **'Add charge'**
  String get chargeAddAction;

  /// Snackbar message when a charge is successfully added
  ///
  /// In en, this message translates to:
  /// **'Charge added.'**
  String get chargeAdded;

  /// Validation error when charge amount is missing or zero
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get errChargeAmount;

  /// Validation error when charge type is not selected
  ///
  /// In en, this message translates to:
  /// **'Choose a charge type.'**
  String get errChargeType;

  /// Title for cancelling a charge confirm sheet
  ///
  /// In en, this message translates to:
  /// **'Cancel this charge?'**
  String get chargeCancelTitle;

  /// Label for reason field when cancelling a charge
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get chargeCancelReason;

  /// Destructive button label to cancel a charge
  ///
  /// In en, this message translates to:
  /// **'Cancel charge'**
  String get chargeCancelAction;

  /// Snackbar message when a charge is cancelled
  ///
  /// In en, this message translates to:
  /// **'Charge cancelled.'**
  String get chargeCancelledToast;

  /// Validation error when cancellation reason is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a reason for cancelling this charge.'**
  String get errChargeReason;
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
