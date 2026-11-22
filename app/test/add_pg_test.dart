import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/bed_occupancy.dart';
import 'package:app/features/owner/domain/city.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/pg_switcher_item.dart';
import 'package:app/features/owner/domain/room_type.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/add_pg_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<City> cities = const [
    City(id: 1, name: 'Bengaluru', stateName: 'Karnataka'),
    City(id: 2, name: 'Chennai', stateName: 'Tamil Nadu'),
    City(id: 3, name: 'Hyderabad', stateName: 'Telangana'),
  ];
  List<PgSwitcherItem> ownerPgs = const [];

  String? createdName;
  String? createdLine1;
  int? createdCityId;
  String? createdPincode;
  String? createdArea;
  String? createdContactPhone;
  String? createdGenderPolicy;

  @override
  Future<List<City>> getCities() async => cities;

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => ownerPgs;

  @override
  Future<List<RoomType>> getRoomTypes() async => const [];

  @override
  Future<List<BedOccupancy>> getBedOccupancy(String pgId) async => const [];

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
  }) async {
    createdName = name;
    createdLine1 = line1;
    createdCityId = cityId;
    createdPincode = pincode;
    createdArea = area;
    createdContactPhone = contactPhone;
    createdGenderPolicy = genderPolicy;
    return 'pg-new-123';
  }

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
  }) async => 'stay-123';

  @override
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<PgOverview?> getPgOverview(String pgId) async => null;

  @override
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId) async => null;

  @override
  Future<void> setStayRent({
    required String stayId,
    required int monthlyRentPaise,
    required DateTime effectiveFrom,
  }) async {}
}

class MockAuthRepo implements AuthRepository {
  String? selectedPgId;
  String? lastView;

  AuthContext myContext = const AuthContext(
    person: AuthPerson(
      id: 'person-owner-1',
      phone: '+919876543210',
    ),
  );

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthContext> getMyContext() async => myContext;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getSelectedPgId() async => selectedPgId;

  @override
  Future<void> setSelectedPgId(String pgId) async {
    selectedPgId = pgId;
  }

  @override
  Future<String?> getLastView() async => lastView;

  @override
  Future<void> setLastView(String view) async {
    lastView = view;
  }
}

Widget createTestApp({
  required MockOwnerRepo ownerRepo,
  required MockAuthRepo authRepo,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.ownerPgNew,
    routes: [
      GoRoute(
        path: RoutePaths.ownerPgNew,
        builder: (context, state) => const AddPgScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerHome,
        builder: (context, state) => const Scaffold(body: Text('Owner Home Screen')),
      ),
      GoRoute(
        path: RoutePaths.gate,
        builder: (context, state) => const Scaffold(body: Text('Role Gate Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(ownerRepo),
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('AddPgScreen renders all sections, fields, pre-filled phone and button',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    expect(find.text('Add your PG'), findsOneWidget);
    expect(find.text('About your PG'), findsOneWidget);
    expect(find.text('PG name'), findsOneWidget);
    expect(find.text('Who stays here'), findsOneWidget);
    expect(find.text('Men'), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
    expect(find.text('Anyone'), findsOneWidget);

    expect(find.text('Address'), findsNWidgets(2)); // section header + field label
    expect(find.text('Building, street'), findsOneWidget);
    expect(find.text('Area (optional)'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Choose a city'), findsOneWidget);
    expect(find.text('Pincode (optional)'), findsOneWidget);

    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Contact number (optional)'), findsOneWidget);
    expect(find.text('Guests see this number to contact you.'), findsOneWidget);
    expect(find.text('98765 43210'), findsOneWidget); // Pre-filled contact

    expect(find.text('Create PG'), findsOneWidget);
  });

  testWidgets('Shows validation errors when submitting empty form', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create PG'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the PG name.'), findsOneWidget);
    expect(find.text('Enter the address.'), findsOneWidget);
    expect(find.text('Choose a city.'), findsOneWidget);
  });

  testWidgets('Validates pincode when entered incorrectly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    final pincodeFinder = find.descendant(
      of: find.widgetWithText(AppTextField, 'Pincode (optional)'),
      matching: find.byType(TextField),
    );
    await tester.enterText(pincodeFinder, '012345');
    await tester.tap(find.text('Create PG'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a 6-digit pincode.'), findsOneWidget);
  });

  testWidgets('Selects city using OptionSheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    final cityFieldFinder = find.text('Choose a city');
    await tester.ensureVisible(cityFieldFinder);
    await tester.pumpAndSettle();
    await tester.tap(cityFieldFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text('Karnataka'), findsOneWidget);

    await tester.tap(find.text('Bengaluru'));
    await tester.pumpAndSettle();

    expect(find.text('Bengaluru'), findsOneWidget);
  });

  testWidgets('Successful PG creation navigates to owner home and shows snackbar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    // 1. Enter PG Name
    final nameFinder = find.descendant(
      of: find.widgetWithText(AppTextField, 'PG name'),
      matching: find.byType(TextField),
    );
    await tester.enterText(nameFinder, 'Greenfield Luxury PG');

    // 2. Select Gender Policy
    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();

    // 3. Enter Address
    final addressFinder = find.descendant(
      of: find.widgetWithText(AppTextField, 'Address'),
      matching: find.byType(TextField),
    );
    await tester.enterText(addressFinder, '123 4th Cross, Koramangala');

    // 4. Enter Area
    final areaFinder = find.descendant(
      of: find.widgetWithText(AppTextField, 'Area (optional)'),
      matching: find.byType(TextField),
    );
    await tester.enterText(areaFinder, '5th Block');

    // 5. Select City
    final cityFieldFinder = find.text('Choose a city');
    await tester.ensureVisible(cityFieldFinder);
    await tester.pumpAndSettle();
    await tester.tap(cityFieldFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bengaluru'));
    await tester.pumpAndSettle();

    // 6. Enter Pincode
    final pincodeFinder = find.descendant(
      of: find.widgetWithText(AppTextField, 'Pincode (optional)'),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(pincodeFinder);
    await tester.pumpAndSettle();
    await tester.enterText(pincodeFinder, '560095');

    // 7. Submit
    await tester.tap(find.text('Create PG'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(ownerRepo.createdName, equals('Greenfield Luxury PG'));
    expect(ownerRepo.createdLine1, equals('123 4th Cross, Koramangala'));
    expect(ownerRepo.createdArea, equals('5th Block'));
    expect(ownerRepo.createdCityId, equals(1));
    expect(ownerRepo.createdPincode, equals('560095'));
    expect(ownerRepo.createdGenderPolicy, equals('women'));
    expect(ownerRepo.createdContactPhone, equals('+919876543210'));

    expect(authRepo.selectedPgId, equals('pg-new-123'));
    expect(authRepo.lastView, equals('owner'));
    expect(find.text('Owner Home Screen'), findsOneWidget);
  });
}
