import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/ledger_row.dart';
import 'package:app/core/widgets/status_chip.dart';
import 'package:app/core/widgets/underline_tabs.dart';
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
import 'package:app/features/owner/presentation/screens/owner_guests_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<GuestListItem> guests = [];
  PgOverview? overview;

  @override
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  }) async =>
      guests;

  @override
  Future<PgOverview?> getPgOverview(String pgId) async => overview;

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
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
  String role = 'owner',
  int initialTabIndex = 0,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.ownerGuests,
    routes: [
      GoRoute(
        path: RoutePaths.ownerGuests,
        builder: (context, state) =>
            OwnerGuestsScreen(initialTabIndex: initialTabIndex),
      ),
      GoRoute(
        path: RoutePaths.ownerGuestsNew,
        builder: (context, state) => const Scaffold(
          body: Text('Add Guest Screen (O5)'),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerGuestDetail,
        builder: (context, state) => Scaffold(
          body: Text('Guest Detail Screen: ${state.pathParameters['stayId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(
        MockAuthRepo(
          myContext: AuthContext(
            person: const AuthPerson(id: 'person-1', phone: '+919999999999'),
            pgs: [AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: role)],
          ),
        ),
      ),
      activePgProvider.overrideWithValue(
        AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: role),
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
  testWidgets('EmptyState shown when PG has no guests, add guest button opens O5', (tester) async {
    final repo = MockOwnerRepo();
    repo.guests = [];
    repo.overview = const PgOverview(pgId: 'pg-1');

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('No guests yet'), findsOneWidget);
    expect(find.text('Add your first guest to start tracking rent.'), findsOneWidget);
    expect(find.text('Add guest'), findsOneWidget);

    // Tap Add guest button
    await tester.tap(find.text('Add guest'));
    await tester.pumpAndSettle();

    expect(find.text('Add Guest Screen (O5)'), findsOneWidget);
  });

  testWidgets('Caretaker role hides plus icon and empty state add guest button', (tester) async {
    final repo = MockOwnerRepo();
    repo.guests = [];
    repo.overview = const PgOverview(pgId: 'pg-1');

    await tester.pumpWidget(_wrapScreen(repo: repo, role: 'caretaker'));
    await tester.pumpAndSettle();

    expect(find.text('No guests yet'), findsOneWidget);
    expect(find.text('Add guest'), findsNothing);
    expect(find.byIcon(AppIcons.add), findsNothing);
  });

  testWidgets('UnderlineTabs display counts from pgOverview', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(
      pgId: 'pg-1',
      openCount: 15,
      overdueCount: 3,
      dueCount: 2,
      paidCount: 10,
      pastCount: 4,
    );
    repo.guests = [
      const GuestListItem(
        stayId: 's-1',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Aarav Patel',
        phone: '+919876543210',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        attentionState: 'paid',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    final tabsFinder = find.byType(UnderlineTabs);
    expect(find.descendant(of: tabsFinder, matching: find.text('All')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('15')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('Overdue')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('3')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('Due')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('2')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('Paid')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('10')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('Past')), findsOneWidget);
    expect(find.descendant(of: tabsFinder, matching: find.text('4')), findsOneWidget);
  });

  testWidgets('Tab filtering and sorting operates according to spec', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(
      pgId: 'pg-1',
      openCount: 3,
      overdueCount: 1,
      dueCount: 1,
      paidCount: 1,
      pastCount: 1,
    );
    repo.guests = [
      const GuestListItem(
        stayId: 's-overdue',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Kiran Kumar',
        phone: '+919111111111',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        roomNumber: '101',
        bedLabel: 'A',
        overduePaise: 650000,
        outstandingPaise: 650000,
        oldestUnpaidDueDate: '2026-10-27',
        attentionState: 'overdue',
      ),
      const GuestListItem(
        stayId: 's-due',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-2',
        fullName: 'Deepak Sharma',
        phone: '+919222222222',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 5,
        roomNumber: '102',
        bedLabel: 'B',
        overduePaise: 0,
        outstandingPaise: 400000,
        oldestUnpaidDueDate: '2026-11-05',
        attentionState: 'due',
      ),
      const GuestListItem(
        stayId: 's-paid',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-3',
        fullName: 'Ananya Roy',
        phone: '+919333333333',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        roomNumber: '103',
        bedLabel: 'A',
        overduePaise: 0,
        outstandingPaise: 0,
        creditPaise: 150000,
        attentionState: 'paid',
      ),
      const GuestListItem(
        stayId: 's-past',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-4',
        fullName: 'Rahul Verma',
        phone: '+919444444444',
        stayStatus: 'vacated',
        joinDate: '2025-01-01',
        leaveDate: '2026-11-01',
        billingDay: 1,
        roomNumber: '104',
        outstandingPaise: 200000,
        attentionState: 'past',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Default tab: All. Shows Kiran, Deepak, Ananya (open). Does NOT show Rahul (vacated).
    expect(find.text('Kiran Kumar'), findsOneWidget);
    expect(find.text('Deepak Sharma'), findsOneWidget);
    expect(find.text('Ananya Roy'), findsOneWidget);
    expect(find.text('Rahul Verma'), findsNothing);

    // Verify chips in All tab
    expect(find.byType(StatusChip), findsNWidgets(3));

    final tabsFinder = find.byType(UnderlineTabs);

    // Tap Overdue tab
    await tester.tap(find.descendant(of: tabsFinder, matching: find.text('Overdue')));
    await tester.pumpAndSettle();

    expect(find.text('Kiran Kumar'), findsOneWidget);
    expect(find.text('Deepak Sharma'), findsNothing);
    expect(find.text('Ananya Roy'), findsNothing);

    // Tap Due tab
    await tester.tap(find.descendant(of: tabsFinder, matching: find.text('Due')));
    await tester.pumpAndSettle();

    expect(find.text('Kiran Kumar'), findsNothing);
    expect(find.text('Deepak Sharma'), findsOneWidget);
    expect(find.text('Ananya Roy'), findsNothing);

    // Tap Paid tab
    await tester.tap(find.descendant(of: tabsFinder, matching: find.text('Paid')));
    await tester.pumpAndSettle();

    expect(find.text('Kiran Kumar'), findsNothing);
    expect(find.text('Deepak Sharma'), findsNothing);
    expect(find.text('Ananya Roy'), findsOneWidget);
    expect(find.textContaining('paid up, advance'), findsOneWidget);

    // Tap Past tab
    await tester.tap(find.descendant(of: tabsFinder, matching: find.text('Past')));
    await tester.pumpAndSettle();

    expect(find.text('Rahul Verma'), findsOneWidget);
    expect(find.textContaining('Left 1 Nov'), findsOneWidget);
    expect(find.text('Kiran Kumar'), findsNothing);
  });

  testWidgets('Search row filters guests by name, room or phone', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(pgId: 'pg-1', openCount: 2);
    repo.guests = [
      const GuestListItem(
        stayId: 's-1',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Aarav Patel',
        phone: '+919876543210',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        roomNumber: '204',
        bedLabel: 'A',
        attentionState: 'paid',
      ),
      const GuestListItem(
        stayId: 's-2',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-2',
        fullName: 'Bhavna Sen',
        phone: '+919812345678',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        roomNumber: '105',
        bedLabel: 'B',
        attentionState: 'paid',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('Bhavna Sen'), findsOneWidget);

    // Search by name
    await tester.enterText(find.byType(TextField), 'Bhavna');
    await tester.pumpAndSettle();

    expect(find.text('Aarav Patel'), findsNothing);
    expect(find.text('Bhavna Sen'), findsOneWidget);

    // Search by room number
    await tester.enterText(find.byType(TextField), '204');
    await tester.pumpAndSettle();

    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('Bhavna Sen'), findsNothing);

    // Search by phone digits
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pumpAndSettle();

    expect(find.text('Aarav Patel'), findsNothing);
    expect(find.text('Bhavna Sen'), findsOneWidget);

    // Search query with no match shows filter empty state
    await tester.enterText(find.byType(TextField), 'xyznonexistent');
    await tester.pumpAndSettle();

    expect(find.text('No guests here'), findsOneWidget);
    expect(find.text('Nothing matches this filter.'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('Tapping guest row navigates to guest detail', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(pgId: 'pg-1', openCount: 1);
    repo.guests = [
      const GuestListItem(
        stayId: 'stay-xyz-789',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Manish Gupta',
        phone: '+919876543210',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        roomNumber: '101',
        bedLabel: 'A',
        attentionState: 'paid',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LedgerRow));
    await tester.pumpAndSettle();

    expect(find.text('Guest Detail Screen: stay-xyz-789'), findsOneWidget);
  });

  testWidgets('Top bar plus button opens O5 Add Guest screen', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(pgId: 'pg-1', openCount: 1);
    repo.guests = [
      const GuestListItem(
        stayId: 's-1',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Manish Gupta',
        phone: '+919876543210',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        attentionState: 'paid',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Guest Screen (O5)'), findsOneWidget);
  });
}
