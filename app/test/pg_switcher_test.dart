import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/pg_switcher_title.dart';
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
import 'package:app/features/owner/presentation/screens/owner_home_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<PgSwitcherItem> pgs = const [
    PgSwitcherItem(
      pgId: 'pg-1',
      name: 'Sunrise PG',
      role: 'owner',
      area: 'Indiranagar',
      cityName: 'Bengaluru',
    ),
    PgSwitcherItem(
      pgId: 'pg-2',
      name: 'Lakeview PG',
      role: 'manager',
      area: 'Koramangala',
      cityName: 'Bengaluru',
    ),
  ];

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => pgs;

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
  }) async => 'new-pg-id';
}

class MockAuthRepo implements AuthRepository {
  String? selectedPgId = 'pg-1';
  String? lastView = 'owner';

  AuthContext myContext = const AuthContext(
    person: AuthPerson(
      id: 'person-1',
      phone: '+919876543210',
    ),
    pgs: [
      AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
      AuthPg(pgId: 'pg-2', name: 'Lakeview PG', role: 'manager'),
    ],
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
    initialLocation: RoutePaths.ownerHome,
    routes: [
      GoRoute(
        path: RoutePaths.ownerHome,
        builder: (context, state) => const OwnerHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerPgNew,
        builder: (context, state) => const Scaffold(body: Text('Add PG Screen')),
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
  testWidgets('OwnerHomeScreen displays PgSwitcherTitle with active PG name',
      (tester) async {
    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    expect(find.byType(PgSwitcherTitle), findsOneWidget);
    expect(find.text('Sunrise PG'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
  });

  testWidgets('Tapping PgSwitcherTitle opens PgSwitcherSheet with PG list and checkmark',
      (tester) async {
    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PgSwitcherTitle));
    await tester.pumpAndSettle();

    expect(find.text('Your PGs'), findsOneWidget);
    expect(find.text('Sunrise PG'), findsNWidgets(2)); // top bar + sheet
    expect(find.text('Indiranagar, Bengaluru · Owner'), findsOneWidget);
    expect(find.text('Lakeview PG'), findsOneWidget);
    expect(find.text('Koramangala, Bengaluru · Manager'), findsOneWidget);
    expect(find.text('Add another PG'), findsOneWidget);
    expect(find.byIcon(AppIcons.plus), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget); // On Sunrise PG
  });

  testWidgets('Tapping another PG switches selected PG and updates top bar',
      (tester) async {
    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PgSwitcherTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lakeview PG'));
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.text('Your PGs'), findsNothing);
    // Top bar should now show Lakeview PG
    expect(find.text('Lakeview PG'), findsOneWidget);
    expect(authRepo.selectedPgId, equals('pg-2'));
  });

  testWidgets('Tapping Add another PG opens O1 (Add PG screen)',
      (tester) async {
    final ownerRepo = MockOwnerRepo();
    final authRepo = MockAuthRepo();

    await tester.pumpWidget(createTestApp(ownerRepo: ownerRepo, authRepo: authRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PgSwitcherTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add another PG'));
    await tester.pumpAndSettle();

    expect(find.text('Add PG Screen'), findsOneWidget);
  });
}

