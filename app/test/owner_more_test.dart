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
import 'package:app/features/owner/presentation/screens/owner_more_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(
          pgId: 'pg-1',
          name: 'Green PG',
          role: 'owner',
          area: 'Koramangala',
          cityName: 'Bengaluru',
        ),
      ];

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
  }) async =>
      'new-pg-id';

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
  bool signOutCalled = false;
  String? lastViewSet;
  AuthContext myContext;

  MockAuthRepo({
    this.myContext = const AuthContext(
      person: AuthPerson(
        id: 'person-1',
        phone: '+919876543210',
      ),
      pgs: [
        AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'owner'),
      ],
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
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<String?> getSelectedPgId() async => 'pg-1';

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => 'owner';

  @override
  Future<void> setLastView(String view) async {
    lastViewSet = view;
  }
}

Widget _wrapWithRouter({
  required WidgetRef ref,
  required Widget child,
  List<RouteBase> extraRoutes = const [],
}) {
  final router = GoRouter(
    initialLocation: '/owner/more',
    routes: [
      GoRoute(
        path: '/owner/more',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: RoutePaths.ownerPgNew,
        builder: (context, state) => const Scaffold(
          body: Text('Add PG Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.guestHome,
        builder: (context, state) => const Scaffold(
          body: Text('Guest Home Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const Scaffold(
          body: Text('Sign In Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const Scaffold(
          body: Text('Profile Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerRooms,
        builder: (context, state) => const Scaffold(
          body: Text('Rooms Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerRoomsSetup,
        builder: (context, state) => const Scaffold(
          body: Text('Set Up Rooms Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerRoomsNew,
        builder: (context, state) => const Scaffold(
          body: Text('Add Rooms Page'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerAccounts,
        builder: (context, state) => const Scaffold(
          body: Text('Accounts Page'),
        ),
      ),
      ...extraRoutes,
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  testWidgets('OwnerMoreScreen displays Account section, Add another PG, and Sign out for owner',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockOwner = MockOwnerRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          ownerRepositoryProvider.overrideWithValue(mockOwner),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify sections and rows
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(AppIcons.profile), findsOneWidget);
    expect(find.text('Add another PG'), findsOneWidget);
    expect(find.byIcon(AppIcons.add), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Guest view switch row should not appear since user has no stay
    expect(find.text('Switch to guest view'), findsNothing);

    // Tap "Add another PG"
    await tester.tap(find.text('Add another PG'));
    await tester.pumpAndSettle();
    expect(find.text('Add PG Page'), findsOneWidget);
  });

  testWidgets('OwnerMoreScreen displays Switch to guest view when user also has a stay',
      (tester) async {
    final mockAuth = MockAuthRepo(
      myContext: const AuthContext(
        person: AuthPerson(
          id: 'person-1',
          phone: '+919876543210',
        ),
        pgs: [
          AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'owner'),
        ],
        stays: [
          AuthStay(
            stayId: 'stay-1',
            pgId: 'pg-2',
            pgName: 'Blue PG',
            status: 'active',
          ),
        ],
      ),
    );
    final mockOwner = MockOwnerRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          ownerRepositoryProvider.overrideWithValue(mockOwner),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Switch to guest view is present
    expect(find.text('Switch to guest view'), findsOneWidget);
    expect(find.byIcon(AppIcons.user), findsOneWidget);

    // Tap "Switch to guest view"
    await tester.tap(find.text('Switch to guest view'));
    await tester.pumpAndSettle();

    expect(mockAuth.lastViewSet, equals('guest'));
    expect(find.text('Guest Home Page'), findsOneWidget);
  });

  testWidgets('Sign out button shows ConfirmSheet and signs out on confirmation',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockOwner = MockOwnerRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          ownerRepositoryProvider.overrideWithValue(mockOwner),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Sign out"
    final signOutFinder = find.text('Sign out');
    await tester.ensureVisible(signOutFinder);
    await tester.tap(signOutFinder);
    await tester.pumpAndSettle();

    // ConfirmSheet should appear
    expect(find.text('Sign out of PG App?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel first to verify it dismisses without signing out
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of PG App?'), findsNothing);
    expect(mockAuth.signOutCalled, isFalse);

    // Tap "Sign out" again
    await tester.tap(signOutFinder);
    await tester.pumpAndSettle();

    // Tap the primary "Sign out" action inside ConfirmSheet
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(mockAuth.signOutCalled, isTrue);
    expect(find.text('Sign In Page'), findsOneWidget);
  });

  testWidgets('Tapping Rooms and beds navigates to rooms screen', (tester) async {
    final mockOwner = MockOwnerRepo();
    final mockAuth = MockAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerRepositoryProvider.overrideWithValue(mockOwner),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rooms and beds'), findsOneWidget);
    await tester.tap(find.text('Rooms and beds'));
    await tester.pumpAndSettle();

    expect(find.text('Rooms Page'), findsOneWidget);
  });

  testWidgets('Receiving accounts appears for owner and navigates to accounts screen',
      (tester) async {
    final mockOwner = MockOwnerRepo();
    final mockAuth = MockAuthRepo(
      myContext: const AuthContext(
        person: AuthPerson(id: 'person-1', phone: '+919876543210'),
        pgs: [AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'owner')],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerRepositoryProvider.overrideWithValue(mockOwner),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receiving accounts'), findsOneWidget);
    expect(find.byIcon(AppIcons.bank), findsOneWidget);

    await tester.tap(find.text('Receiving accounts'));
    await tester.pumpAndSettle();

    expect(find.text('Accounts Page'), findsOneWidget);
  });

  testWidgets('Receiving accounts does not appear for non-owner', (tester) async {
    final mockOwner = MockOwnerRepo();
    final mockAuth = MockAuthRepo(
      myContext: const AuthContext(
        person: AuthPerson(id: 'person-1', phone: '+919876543210'),
        pgs: [AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'manager')],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerRepositoryProvider.overrideWithValue(mockOwner),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const OwnerMoreScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receiving accounts'), findsNothing);
  });
}


