import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/status_chip.dart';
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
import 'package:app/features/owner/presentation/screens/owner_guest_detail_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  GuestDetailBundle? bundle;

  @override
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId) async => bundle;

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
  String stayId = 'stay-101',
}) {
  final router = GoRouter(
    initialLocation: '/owner/guests/$stayId',
    routes: [
      GoRoute(
        path: '/owner/guests/:stayId',
        builder: (context, state) => OwnerGuestDetailScreen(
          stayId: state.pathParameters['stayId'] ?? '',
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
  testWidgets('OwnerGuestDetailScreen displays header, balance, details, and waiting notice', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = MockOwnerRepo();
    repo.bundle = const GuestDetailBundle(
      guest: GuestListItem(
        stayId: 'stay-101',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Kiran Kumar',
        phone: '+919876543210',
        stayStatus: 'active',
        joinDate: '2026-06-03',
        billingDay: 12,
        roomNumber: '101',
        bedLabel: 'A',
        monthlyRentPaise: 650000,
        chargedPaise: 2950000,
        paidPaise: 1450000,
        outstandingPaise: 1500000,
        overduePaise: 1500000,
        pendingVerificationPaise: 250000,
        hasSignedIn: false,
        attentionState: 'overdue',
      ),
      charges: [
        ChargeBalance(
          chargeId: 'c-1',
          stayId: 'stay-101',
          description: 'November rent',
          dueDate: '2026-11-12',
          amountPaise: 650000,
          outstandingPaise: 650000,
          status: 'overdue',
        ),
      ],
      payments: [
        PaymentFeedItem(
          paymentId: 'pay-1',
          stayId: 'stay-101',
          amountPaise: 250000,
          paidOn: '2026-11-12',
          status: 'pending',
          methodCode: 'upi',
          methodLabel: 'UPI',
          payerAppLabel: 'PhonePe',
        ),
      ],
      emergencyContact: EmergencyContact(
        id: 'ec-1',
        personId: 'p-1',
        name: 'Ramesh Kumar',
        phone: '+919123456789',
        relationship: 'Father',
        isPrimary: true,
      ),
      documentsCount: 2,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Top bar & Header
    expect(find.text('Kiran Kumar'), findsWidgets);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.textContaining('Room 101, bed A, since 3 Jun 2026'), findsOneWidget);
    expect(find.byType(StatusChip), findsWidgets);

    // Balance sheet
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Charged'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Advance'), findsOneWidget);
    expect(find.textContaining('reported by the guest, waiting for you.'), findsOneWidget);

    // Charges section
    expect(find.text('Charges'), findsOneWidget);
    expect(find.text('November rent'), findsOneWidget);

    // Payments section
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('UPI, PhonePe'), findsOneWidget);

    // Details section
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Day 12 of every month'), findsOneWidget);
    expect(find.text('3 Jun 2026'), findsOneWidget);
    expect(find.text('Not signed in yet'), findsOneWidget);
    expect(find.text('Invite again'), findsOneWidget);
    expect(find.text('Ramesh Kumar (Father)'), findsOneWidget);
    expect(find.text('2 uploaded'), findsOneWidget);
  });

  testWidgets('Vacated stay displays ended subtitle, no status chip, and omits emergency contact/documents', (tester) async {
    final repo = MockOwnerRepo();
    repo.bundle = const GuestDetailBundle(
      guest: GuestListItem(
        stayId: 'stay-past',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-past',
        fullName: 'Rahul Verma',
        phone: '+919988776655',
        stayStatus: 'vacated',
        joinDate: '2025-06-01',
        leaveDate: '2026-11-01',
        billingDay: 1,
        roomNumber: '104',
        bedLabel: 'B',
        monthlyRentPaise: 500000,
        chargedPaise: 1000000,
        paidPaise: 1000000,
        outstandingPaise: 0,
        hasSignedIn: true,
        attentionState: 'past',
      ),
      charges: [],
      payments: [],
      documentsCount: 1,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo, stayId: 'stay-past'));
    await tester.pumpAndSettle();

    expect(find.text('Rahul Verma'), findsWidgets);
    expect(find.textContaining('1 Jun 2025 to 1 Nov 2026'), findsOneWidget);

    // Status chip should not be displayed for past stays
    expect(find.byType(StatusChip), findsNothing);

    // Emergency contact and ID documents should not appear for vacated stays
    expect(find.text('Emergency contact'), findsNothing);
    expect(find.text('ID documents'), findsNothing);
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Invite again'), findsNothing);
  });

  testWidgets('Charges section displays different status chips (paid, partial, void)', (tester) async {
    final repo = MockOwnerRepo();
    repo.bundle = const GuestDetailBundle(
      guest: GuestListItem(
        stayId: 'stay-101',
        pgId: 'pg-1',
        pgName: 'Sunrise PG',
        personId: 'p-1',
        fullName: 'Test Guest',
        phone: '+919999999999',
        stayStatus: 'active',
        joinDate: '2026-01-01',
        billingDay: 1,
        attentionState: 'paid',
      ),
      charges: [
        ChargeBalance(
          chargeId: 'c-1',
          stayId: 'stay-101',
          description: 'October rent',
          dueDate: '2026-10-01',
          amountPaise: 500000,
          status: 'paid',
        ),
        ChargeBalance(
          chargeId: 'c-2',
          stayId: 'stay-101',
          description: 'Electricity bill',
          dueDate: '2026-11-01',
          amountPaise: 80000,
          outstandingPaise: 40000,
          status: 'partial',
        ),
        ChargeBalance(
          chargeId: 'c-3',
          stayId: 'stay-101',
          description: 'Old fine',
          dueDate: '2026-09-01',
          amountPaise: 20000,
          status: 'void',
        ),
      ],
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('October rent'), findsOneWidget);
    expect(find.text('Electricity bill'), findsOneWidget);
    expect(find.text('Old fine'), findsOneWidget);

    expect(find.text('Part-paid'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });
}
