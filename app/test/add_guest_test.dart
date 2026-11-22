import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/date_field.dart';
import 'package:app/core/widgets/money_field.dart';
import 'package:app/core/widgets/phone_field.dart';
import 'package:app/core/widgets/select_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/bed_occupancy.dart';
import 'package:app/features/owner/domain/city.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/pg_switcher_item.dart';
import 'package:app/features/owner/domain/room_type.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/add_guest_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockOwnerRepo implements OwnerRepository {
  List<BedOccupancy> beds = [
    const BedOccupancy(
      bedId: 'bed-1',
      bedLabel: 'A',
      roomId: 'room-101',
      pgId: 'pg-1',
      roomNumber: '101',
      roomTypeLabel: 'Double sharing',
    ),
    const BedOccupancy(
      bedId: 'bed-2',
      bedLabel: 'B',
      roomId: 'room-101',
      pgId: 'pg-1',
      roomNumber: '101',
      roomTypeLabel: 'Double sharing',
    ),
    const BedOccupancy(
      bedId: 'bed-3',
      bedLabel: 'A',
      roomId: 'room-102',
      pgId: 'pg-1',
      roomNumber: '102',
      roomTypeLabel: 'Single room',
      stayId: 'stay-existing', // Occupied
    ),
  ];

  bool throwDuplicateGuest = false;
  bool throwBedTaken = false;

  Map<String, dynamic>? lastCreateParams;

  @override
  Future<List<BedOccupancy>> getBedOccupancy(String pgId) async => beds;

  @override
  Future<String> createStay({
    required String pgId,
    required String phone,
    required String fullName,
    String? bedId,
    required DateTime joinDate,
    required int monthlyRentPaise,
    int depositPaise = 0,
    int? billingDay,
    DateTime? billingStartsOn,
    bool depositAlreadyPaid = false,
  }) async {
    if (throwDuplicateGuest) {
      throw const DuplicateGuestStayException();
    }
    if (throwBedTaken) {
      throw const BedAlreadyTakenException();
    }

    lastCreateParams = {
      'pgId': pgId,
      'phone': phone,
      'fullName': fullName,
      'bedId': bedId,
      'joinDate': joinDate,
      'monthlyRentPaise': monthlyRentPaise,
      'depositPaise': depositPaise,
      'billingDay': billingDay,
      'billingStartsOn': billingStartsOn,
      'depositAlreadyPaid': depositAlreadyPaid,
    };
    return 'new-stay-123';
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(pgId: 'pg-1', name: 'Green PG', role: 'owner'),
      ];

  @override
  Future<List<RoomType>> getRoomTypes() async => const [];

  @override
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async => const [];

  @override
  Future<PaymentAccount?> getPaymentAccount(String id) async => null;

  @override
  Future<PaymentAccount> createPaymentAccount(PaymentAccount account) async => account;

  @override
  Future<PaymentAccount> updatePaymentAccount(PaymentAccount account) async => account;

  @override
  Future<int> addRooms({
    required String pgId,
    required int firstRoomNumber,
    required int roomCount,
    required int bedsPerRoom,
    String? roomTypeCode,
    int? floor,
    String? prefix,
  }) async =>
      roomCount;

  @override
  Future<int> addRoomLayout({
    required String pgId,
    required List<Map<String, dynamic>> rooms,
  }) async =>
      rooms.length;

  @override
  Future<String> createPg({
    required String name,
    required String line1,
    required int cityId,
    String? pincode,
    String? area,
    String? contactPhone,
    String genderPolicy = 'any',
  }) async =>
      'pg-1';
}

Widget createTestWidget({
  required MockOwnerRepo repo,
  String? initialBedId,
}) {
  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      activePgProvider.overrideWithValue(
        const AuthPg(
          pgId: 'pg-1',
          name: 'Green PG',
          role: 'owner',
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: AddGuestScreen(initialBedId: initialBedId),
    ),
  );
}

void main() {
  group('O5 AddGuestScreen', () {
    testWidgets('shows validation errors when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Add guest'), findsWidgets);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Rent and deposit'), findsOneWidget);

      // Tap submit button
      final submitButton = find.widgetWithText(AppButton, 'Add guest');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
      expect(find.text('Enter the guest\'s name.'), findsOneWidget);
      expect(find.text('Enter the monthly rent.'), findsOneWidget);
      expect(repo.lastCreateParams, isNull);
    });

    testWidgets('fills form and successfully submits, opening invite sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Enter phone
      final phoneField = find.byType(PhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextField)),
        '9876512345',
      );
      await tester.pumpAndSettle();

      // Enter name
      final nameField = find.widgetWithText(AppTextField, 'Full name');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextField)),
        'Ramesh Kumar',
      );
      await tester.pumpAndSettle();

      // Select bed: tap bed field
      final bedField = find.widgetWithText(SelectField, 'Bed (optional)');
      await tester.tap(bedField);
      await tester.pumpAndSettle();

      // OptionSheet options: No bed yet, Room 101, bed A, Room 101, bed B (Room 102 bed A is occupied, shouldn't show)
      expect(find.text('No bed yet'), findsOneWidget);
      expect(find.text('Room 101, bed A'), findsOneWidget);
      expect(find.text('Room 101, bed B'), findsOneWidget);
      expect(find.text('Room 102, bed A'), findsNothing);

      await tester.tap(find.text('Room 101, bed A'));
      await tester.pumpAndSettle();

      // Enter rent
      final rentField = find.widgetWithText(MoneyField, 'Monthly rent');
      await tester.enterText(
        find.descendant(of: rentField, matching: find.byType(TextField)),
        '8000',
      );
      await tester.pumpAndSettle();

      // Enter deposit
      final depositField = find.widgetWithText(MoneyField, 'Security deposit (optional)');
      await tester.enterText(
        find.descendant(of: depositField, matching: find.byType(TextField)),
        '10000',
      );
      await tester.pumpAndSettle();

      // Submit
      final submitButton = find.widgetWithText(AppButton, 'Add guest');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify repo was called with right params
      expect(repo.lastCreateParams, isNotNull);
      expect(repo.lastCreateParams!['phone'], '+919876512345');
      expect(repo.lastCreateParams!['fullName'], 'Ramesh Kumar');
      expect(repo.lastCreateParams!['bedId'], 'bed-1');
      expect(repo.lastCreateParams!['monthlyRentPaise'], 800000);
      expect(repo.lastCreateParams!['depositPaise'], 1000000);
      expect(repo.lastCreateParams!['billingStartsOn'], isNull);
      expect(repo.lastCreateParams!['depositAlreadyPaid'], false);

      // Verify invite sheet is shown
      expect(find.text('Guest added'), findsOneWidget);
      expect(find.text('Ask Ramesh Kumar to sign in with +91 98765 12345.'), findsOneWidget);
      expect(find.text('Invite on WhatsApp'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('already staying switch reveals start date and deposit switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Start billing from'), findsNothing);
      expect(find.text('Deposit already received'), findsNothing);

      // Toggle already staying
      await tester.tap(find.text('Already staying here'));
      await tester.pumpAndSettle();

      expect(find.text('Start billing from'), findsOneWidget);
      expect(find.text('Deposit already received'), findsOneWidget);

      // Enter required fields
      final phoneField = find.byType(PhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextField)),
        '9123456789',
      );
      final nameField = find.widgetWithText(AppTextField, 'Full name');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextField)),
        'Suresh',
      );

      final rentField = find.widgetWithText(MoneyField, 'Monthly rent');
      await tester.enterText(
        find.descendant(of: rentField, matching: find.byType(TextField)),
        '6500',
      );
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(AppButton, 'Add guest');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(repo.lastCreateParams!['billingStartsOn'], isNotNull);
      expect(repo.lastCreateParams!['depositAlreadyPaid'], true);
    });

    testWidgets('preselects bed when initialBedId is provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      await tester.pumpWidget(createTestWidget(repo: repo, initialBedId: 'bed-2'));
      await tester.pumpAndSettle();

      expect(find.text('Room 101, bed B'), findsOneWidget);
    });

    testWidgets('shows duplicate guest error from database', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      repo.throwDuplicateGuest = true;

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      final phoneField = find.byType(PhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextField)),
        '9876543210',
      );
      final nameField = find.widgetWithText(AppTextField, 'Full name');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextField)),
        'Duplicate Guest',
      );
      final rentField = find.widgetWithText(MoneyField, 'Monthly rent');
      await tester.enterText(
        find.descendant(of: rentField, matching: find.byType(TextField)),
        '5000',
      );
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(AppButton, 'Add guest');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('This guest is already staying in this PG.'), findsWidgets);
    });

    testWidgets('shows bed taken error from database', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      repo.throwBedTaken = true;

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      final phoneField = find.byType(PhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextField)),
        '9876543210',
      );
      final nameField = find.widgetWithText(AppTextField, 'Full name');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextField)),
        'Guest Name',
      );
      final rentField = find.widgetWithText(MoneyField, 'Monthly rent');
      await tester.enterText(
        find.descendant(of: rentField, matching: find.byType(TextField)),
        '5000',
      );
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(AppButton, 'Add guest');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('That bed was just taken. Choose another.'), findsWidgets);
    });

    testWidgets('shows notice when joining date is in the past', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockOwnerRepo();
      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('Joining date is in the past. Turn on Already staying here below if needed.'),
        findsNothing,
      );

      // Open date picker
      final joinDateField = find.widgetWithText(DateField, 'Joining date');
      await tester.tap(joinDateField);
      await tester.pumpAndSettle();

      // Tap 1st day of month
      await tester.tap(find.text('1').first);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.text('Joining date is in the past. Turn on Already staying here below if needed.'),
        findsOneWidget,
      );
    });
  });
}
