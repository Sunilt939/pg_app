import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
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
import 'package:app/features/owner/presentation/screens/owner_room_detail_screen.dart';
import 'package:app/features/owner/presentation/screens/owner_rooms_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<BedOccupancy> beds = [];

  @override
  Future<List<BedOccupancy>> getBedOccupancy(String pgId) async => beds;

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
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

  @override
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId) async => null;

  @override
  Future<void> setStayRent({
    required String stayId,
    required int monthlyRentPaise,
    required DateTime effectiveFrom,
  }) async {}

  @override
  Future<List<ChargeType>> getChargeTypes() async => const [];

  @override
  Future<void> addCharge({
    required String stayId,
    required String chargeTypeCode,
    required int amountPaise,
    required DateTime dueDate,
    String? description,
    DateTime? periodMonth,
  }) async {}

  @override
  Future<void> voidCharge({
    required String chargeId,
    required String reason,
  }) async {}

  @override
  Future<void> correctGuestName({
    required String personId,
    required String fullName,
  }) async {}

  @override
  Future<void> vacateStay({
    required String stayId,
    DateTime? leaveDate,
  }) async {}

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => [];

  @override
  Future<List<UpiApp>> getUpiApps() async => [];

  @override
  Future<String> recordPayment({
    required String stayId,
    required int amountPaise,
    required String methodCode,
    DateTime? paidOn,
    String? accountId,
    String? note,
    String? payerAppCode,
    String? utr,
  }) async => 'pay-123';
}

class MockAuthRepo implements AuthRepository {
  final AuthContext myContext;

  MockAuthRepo({
    this.myContext = const AuthContext(
      person: AuthPerson(id: 'person-1', phone: '+919999999999'),
      pgs: [AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner')],
    ),
  });

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

Widget _wrapScreen({
  required OwnerRepository repo,
  String initialLocation = RoutePaths.ownerRooms,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.ownerRooms,
        builder: (context, state) => const OwnerRoomsScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerRoomsSetup,
        builder: (context, state) => const Scaffold(
          body: Text('Set Up Rooms Screen'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerRoomsNew,
        builder: (context, state) => const Scaffold(
          body: Text('Add Rooms Screen'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerRoomDetail,
        builder: (context, state) => OwnerRoomDetailScreen(
          roomId: state.pathParameters['roomId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerGuestsNew,
        builder: (context, state) => Scaffold(
          body: Text('Add Guest: bedId=${state.uri.queryParameters['bedId']}'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerGuestDetail,
        builder: (context, state) => Scaffold(
          body: Text('Guest Detail: ${state.pathParameters['stayId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(MockAuthRepo()),
      activePgProvider.overrideWithValue(
        const AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
      ),
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
  testWidgets('EmptyState shown when PG has no rooms and actions navigate', (tester) async {
    final repo = MockOwnerRepo();
    repo.beds = [];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Rooms and beds'), findsOneWidget);
    expect(find.text('No rooms yet'), findsOneWidget);
    expect(
      find.text('Add your rooms and beds so you can give each guest a bed.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Add rooms'), findsOneWidget);

    // Tap Add rooms button in EmptyState -> navigates to /owner/rooms/setup
    await tester.tap(find.widgetWithText(AppButton, 'Add rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Set Up Rooms Screen'), findsOneWidget);
  });

  testWidgets('Top bar plus action navigates to /owner/rooms/new', (tester) async {
    final repo = MockOwnerRepo();
    repo.beds = [];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    final plusIcon = find.byIcon(AppIcons.add);
    expect(plusIcon, findsOneWidget);
    await tester.tap(plusIcon);
    await tester.pumpAndSettle();

    expect(find.text('Add Rooms Screen'), findsOneWidget);
  });

  testWidgets('Populated rooms list shows summary, floor groups, badges, and natural order',
      (tester) async {
    final repo = MockOwnerRepo();
    repo.beds = [
      // Floor 1 - Room 101 (2 beds: 1 occupied, 1 free)
      const BedOccupancy(
        bedId: 'b-101-a',
        bedLabel: 'A',
        roomId: 'r-101',
        pgId: 'pg-1',
        roomNumber: '101',
        floor: 1,
        roomTypeLabel: 'Double',
        stayId: 'stay-101',
        occupantName: 'Rohan Kumar',
        occupantPhone: '+919876543210',
      ),
      const BedOccupancy(
        bedId: 'b-101-b',
        bedLabel: 'B',
        roomId: 'r-101',
        pgId: 'pg-1',
        roomNumber: '101',
        floor: 1,
        roomTypeLabel: 'Double',
      ),
      // Floor 1 - Room 102 (1 bed: occupied) -> Full
      const BedOccupancy(
        bedId: 'b-102-a',
        bedLabel: 'A',
        roomId: 'r-102',
        pgId: 'pg-1',
        roomNumber: '102',
        floor: 1,
        roomTypeLabel: 'Single',
        stayId: 'stay-102',
        occupantName: 'Amit Verma',
        occupantPhone: '+919876543211',
      ),
      // Floor 2 - Room 201 (3 beds: all free)
      const BedOccupancy(
        bedId: 'b-201-a',
        bedLabel: 'A',
        roomId: 'r-201',
        pgId: 'pg-1',
        roomNumber: '201',
        floor: 2,
        roomTypeLabel: '3 sharing',
      ),
      const BedOccupancy(
        bedId: 'b-201-b',
        bedLabel: 'B',
        roomId: 'r-201',
        pgId: 'pg-1',
        roomNumber: '201',
        floor: 2,
        roomTypeLabel: '3 sharing',
      ),
      const BedOccupancy(
        bedId: 'b-201-c',
        bedLabel: 'C',
        roomId: 'r-201',
        pgId: 'pg-1',
        roomNumber: '201',
        floor: 2,
        roomTypeLabel: '3 sharing',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Summary line: 3 rooms, 6 beds, 4 free
    expect(find.text('3 rooms, 6 beds, 4 free'), findsOneWidget);

    // Floor section headers
    expect(find.text('Floor 1'), findsOneWidget);
    expect(find.text('Floor 2'), findsOneWidget);

    // Room titles and room numbers
    expect(find.text('101'), findsOneWidget);
    expect(find.text('Double'), findsOneWidget);
    expect(find.text('2 beds, 1 free'), findsOneWidget);
    expect(find.text('1 free'), findsOneWidget);

    expect(find.text('102'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('1 bed, 0 free'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);

    expect(find.text('201'), findsOneWidget);
    expect(find.text('3 sharing'), findsOneWidget);
    expect(find.text('3 beds, 3 free'), findsOneWidget);
    expect(find.text('3 free'), findsOneWidget);
  });

  testWidgets('Tapping a room row opens Room detail page with beds and occupant/add guest',
      (tester) async {
    final repo = MockOwnerRepo();
    repo.beds = [
      const BedOccupancy(
        bedId: 'b-101-a',
        bedLabel: 'A',
        roomId: 'r-101',
        pgId: 'pg-1',
        roomNumber: '101',
        floor: 1,
        roomTypeLabel: 'Double',
        stayId: 'stay-101',
        occupantName: 'Rohan Kumar',
        occupantPhone: '+919876543210',
      ),
      const BedOccupancy(
        bedId: 'b-101-b',
        bedLabel: 'B',
        roomId: 'r-101',
        pgId: 'pg-1',
        roomNumber: '101',
        floor: 1,
        roomTypeLabel: 'Double',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Tap on room 101
    await tester.tap(find.text('Double'));
    await tester.pumpAndSettle();

    // In Room detail page:
    expect(find.text('Room 101'), findsOneWidget);

    // Bed A occupied
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Rohan Kumar'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);

    // Bed B free with Add guest action
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Add guest'), findsOneWidget);

    // Tap on Rohan Kumar row opens guest detail
    await tester.tap(find.text('Rohan Kumar'));
    await tester.pumpAndSettle();
    expect(find.text('Guest Detail: stay-101'), findsOneWidget);
  });

  testWidgets('Tapping Add guest on free bed navigates to add guest with bedId',
      (tester) async {
    final repo = MockOwnerRepo();
    repo.beds = [
      const BedOccupancy(
        bedId: 'b-101-b',
        bedLabel: 'B',
        roomId: 'r-101',
        pgId: 'pg-1',
        roomNumber: '101',
        floor: 1,
      ),
    ];

    await tester.pumpWidget(
      _wrapScreen(
        repo: repo,
        initialLocation: '/owner/rooms/r-101',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Room 101'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Add guest'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Add guest'));
    await tester.pumpAndSettle();

    expect(find.text('Add Guest: bedId=b-101-b'), findsOneWidget);
  });
}
