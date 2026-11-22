import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
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
import 'package:app/features/owner/presentation/screens/add_rooms_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<RoomType> roomTypes = const [
    RoomType(id: 1, code: 'single', label: 'Single'),
    RoomType(id: 2, code: 'double', label: '2 sharing'),
    RoomType(id: 3, code: 'triple', label: '3 sharing'),
    RoomType(id: 4, code: 'dormitory', label: 'Dormitory'),
  ];

  String? lastPgId;
  int? lastFirstRoomNumber;
  int? lastRoomCount;
  int? lastBedsPerRoom;
  String? lastRoomTypeCode;
  int? lastFloor;
  String? lastPrefix;
  bool shouldThrowClash = false;

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(
          pgId: 'pg-test-1',
          name: 'Green PG',
          role: 'owner',
        ),
      ];

  @override
  Future<List<RoomType>> getRoomTypes() async => roomTypes;

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
  }) async {
    if (shouldThrowClash) {
      throw Exception('Room ${prefix ?? ''}$firstRoomNumber already exists in this PG');
    }
    lastPgId = pgId;
    lastFirstRoomNumber = firstRoomNumber;
    lastRoomCount = roomCount;
    lastBedsPerRoom = bedsPerRoom;
    lastRoomTypeCode = roomTypeCode;
    lastFloor = floor;
    lastPrefix = prefix;
    return roomCount;
  }

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
      'new-pg';

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
  }) async =>
      'stay-123';

  @override
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<PgOverview?> getPgOverview(String pgId) async => null;
}

class MockAuthRepo implements AuthRepository {
  final AuthContext myContext;

  MockAuthRepo({required this.myContext});

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
  Future<String?> getSelectedPgId() async => myContext.pgs.firstOrNull?.pgId;

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => 'owner';

  @override
  Future<void> setLastView(String view) async {}
}

Widget _buildTestApp({
  required MockOwnerRepo repo,
  String pgId = 'pg-test-1',
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.ownerRoomsNew,
    routes: [
      GoRoute(
        path: RoutePaths.ownerRoomsNew,
        builder: (context, state) => const AddRoomsScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerMore,
        builder: (context, state) => const Scaffold(
          body: Text('Owner More Screen'),
        ),
      ),
    ],
  );

  final authContext = AuthContext(
    person: const AuthPerson(id: 'person-1', phone: '+919876543210'),
    pgs: [
      AuthPg(pgId: pgId, name: 'Green PG', role: 'owner'),
    ],
  );
  final mockAuth = MockAuthRepo(myContext: authContext);

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(mockAuth),
      activePgProvider.overrideWithValue(AuthPg(pgId: pgId, name: 'Green PG', role: 'owner')),
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

  testWidgets('Renders all fields in order with defaults', (tester) async {
    final repo = MockOwnerRepo();
    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Top bar title
    expect(find.text('Add rooms'), findsWidgets);

    // Form fields
    expect(find.text('First room number'), findsOneWidget);
    expect(find.text('Number of rooms'), findsOneWidget);
    expect(find.text('Beds in each room'), findsOneWidget);
    expect(find.text('Room type (optional)'), findsOneWidget);
    expect(find.text('Floor (optional)'), findsOneWidget);
    expect(find.text('Number prefix (optional)'), findsOneWidget);
    expect(find.text('Letters before the number, if any'), findsOneWidget);

    // Default values
    expect(find.text('1'), findsWidgets); // count default is 1
    expect(find.text('2'), findsOneWidget); // beds default is 2
    expect(find.text('Not set'), findsOneWidget); // room type default is Not set

    // Sticky button
    expect(find.widgetWithText(AppButton, 'Add rooms'), findsOneWidget);
  });

  Finder fieldInput(String key) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

  testWidgets('Live line appears and updates when first room number and count are valid', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = MockOwnerRepo();
    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Initially no live line because first room number is empty
    expect(find.textContaining('This will add'), findsNothing);

    // Enter first room number 101
    await tester.enterText(fieldInput('first_room_number_field'), '101');
    await tester.pumpAndSettle();

    // Now live line is visible (count=1, beds=2)
    expect(find.text('This will add 1 rooms, 101 to 101, with 2 beds each (A, B).'), findsOneWidget);

    // Change count to 10
    await tester.enterText(fieldInput('room_count_field'), '10');
    await tester.pumpAndSettle();

    expect(find.text('This will add 10 rooms, 101 to 110, with 2 beds each (A, B).'), findsOneWidget);

    // Enter prefix 'A-'
    await tester.enterText(fieldInput('room_prefix_field'), 'A-');
    await tester.pumpAndSettle();

    expect(find.text('This will add 10 rooms, A-101 to A-110, with 2 beds each (A, B).'), findsOneWidget);
  });

  testWidgets('Shows validation errors when required inputs are empty or invalid', (tester) async {
    final repo = MockOwnerRepo();
    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // First room number is empty, tap Add rooms
    await tester.tap(find.widgetWithText(AppButton, 'Add rooms'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the first room number.'), findsOneWidget);

    // Clear count field and enter 0
    await tester.enterText(fieldInput('room_count_field'), '0');
    await tester.tap(find.widgetWithText(AppButton, 'Add rooms'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a number from 1 to 100.'), findsOneWidget);
  });

  testWidgets('Selecting beds from OptionSheet updates beds and preview', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = MockOwnerRepo();
    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Enter first room number 201
    await tester.enterText(fieldInput('first_room_number_field'), '201');
    await tester.pumpAndSettle();

    // Tap Beds SelectField
    await tester.tap(find.byKey(const Key('room_beds_field')));
    await tester.pumpAndSettle();

    // OptionSheet opens with 1 to 12
    expect(find.text('Beds in each room'), findsWidgets);
    expect(find.text('3'), findsOneWidget);

    // Tap 3
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // Beds updated to 3 and preview reflects labels (A, B, C)
    expect(find.text('This will add 1 rooms, 201 to 201, with 3 beds each (A, B, C).'), findsOneWidget);
  });

  testWidgets('Selecting room type from OptionSheet updates room type', (tester) async {
    final repo = MockOwnerRepo();
    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Tap Room type SelectField
    await tester.tap(find.byKey(const Key('room_type_field')));
    await tester.pumpAndSettle();

    // OptionSheet opens with Not set and room types
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('2 sharing'), findsOneWidget);

    // Tap Single
    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();

    expect(find.text('Single'), findsOneWidget);
  });

  testWidgets('Database clash error shows under first room number field', (tester) async {
    final repo = MockOwnerRepo();
    repo.shouldThrowClash = true;

    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(fieldInput('first_room_number_field'), '101');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Add rooms'));
    await tester.pumpAndSettle();

    expect(find.text('Room 101 already exists in this PG'), findsOneWidget);
  });

  testWidgets('Successful submission calls addRooms and shows snackbar', (tester) async {
    final repo = MockOwnerRepo();

    await tester.pumpWidget(_buildTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Enter first room number 101
    await tester.enterText(fieldInput('first_room_number_field'), '101');

    // Enter count 5
    await tester.enterText(fieldInput('room_count_field'), '5');

    // Enter floor 1
    await tester.enterText(fieldInput('room_floor_field'), '1');

    await tester.pumpAndSettle();

    // Tap Add rooms
    await tester.tap(find.widgetWithText(AppButton, 'Add rooms'));
    await tester.pumpAndSettle();

    // Verify repository called with correct arguments
    expect(repo.lastPgId, 'pg-test-1');
    expect(repo.lastFirstRoomNumber, 101);
    expect(repo.lastRoomCount, 5);
    expect(repo.lastBedsPerRoom, 2);
    expect(repo.lastFloor, 1);

    // Verify snackbar
    expect(find.text('5 rooms added.'), findsOneWidget);
  });
}
