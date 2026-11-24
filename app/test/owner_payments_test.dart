import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/room_tile.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_payments_screen.dart';

class MockAuthRepo implements AuthRepository {
  final AuthContext myContext;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
}

class MockOwnerRepo implements OwnerRepository {
  List<PaymentFeedItem> payments = [];
  PgOverview? overview;
  bool shouldThrow = false;
  String? confirmedPaymentId;
  String? rejectedPaymentId;
  String? rejectedReason;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PaymentFeedItem>> getPgPayments(String pgId) async {
    if (shouldThrow) throw Exception('Failed to load payments');
    return payments;
  }

  @override
  Future<PgOverview?> getPgOverview(String pgId) async {
    if (shouldThrow) throw Exception('Failed to load overview');
    return overview;
  }

  @override
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async => [];

  @override
  Future<void> confirmPayment({
    required String paymentId,
    String? accountId,
  }) async {
    confirmedPaymentId = paymentId;
  }

  @override
  Future<void> rejectPayment({
    required String paymentId,
    required String reason,
  }) async {
    rejectedPaymentId = paymentId;
    rejectedReason = reason;
  }
}

Widget _wrapScreen({
  required MockOwnerRepo repo,
  String initialLocation = '/owner/payments',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/owner/payments',
        builder: (context, state) => const OwnerPaymentsScreen(),
      ),
      GoRoute(
        path: '/owner/payments/:paymentId',
        builder: (context, state) => Scaffold(
          body: Text('Payment detail for ${state.pathParameters['paymentId']}'),
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
  testWidgets('O9: Renders top bar with PG title and UnderlineTabs with badge', (tester) async {
    final repo = MockOwnerRepo();
    repo.overview = const PgOverview(
      pgId: 'pg-1',
      pendingPaymentCount: 3,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Sunrise PG'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('O9: Waiting tab shows empty state when no pending payments', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Nothing is waiting'), findsOneWidget);
    expect(find.text('Payments your guests report will appear here for you to confirm.'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('O9: Waiting tab lists pending payments oldest first', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [
      const PaymentFeedItem(
        paymentId: 'pay-2',
        stayId: 'stay-2',
        fullName: 'Rahul Sharma',
        roomNumber: '102',
        amountPaise: 900000,
        paidOn: '2026-11-22',
        createdAt: '2026-11-22T10:00:00Z',
        status: 'pending',
        methodCode: 'upi',
        methodLabel: 'UPI',
      ),
      const PaymentFeedItem(
        paymentId: 'pay-1',
        stayId: 'stay-1',
        fullName: 'Aarav Patel',
        roomNumber: '101',
        amountPaise: 800000,
        paidOn: '2026-11-20',
        createdAt: '2026-11-20T10:00:00Z',
        status: 'pending',
        methodCode: 'upi',
        methodLabel: 'UPI',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Oldest first: pay-1 (Aarav) then pay-2 (Rahul)
    final aaravFinder = find.text('Aarav Patel');
    final rahulFinder = find.text('Rahul Sharma');
    expect(aaravFinder, findsOneWidget);
    expect(rahulFinder, findsOneWidget);

    expect(tester.getTopLeft(aaravFinder).dy < tester.getTopLeft(rahulFinder).dy, isTrue);

    expect(find.text('Reported ₹8,000 by UPI, 20 Nov 2026'), findsOneWidget);
    expect(find.text('Reported ₹9,000 by UPI, 22 Nov 2026'), findsOneWidget);
    expect(find.byType(RoomTile), findsNWidgets(2));
    expect(find.text('101'), findsOneWidget);
    expect(find.text('102'), findsOneWidget);

    // Confirm and Reject buttons exist for each row
    expect(find.widgetWithText(AppButton, 'Confirm'), findsNWidgets(2));
    expect(find.widgetWithText(AppButton, 'Reject'), findsNWidgets(2));
  });

  testWidgets('O9: Tapping waiting row opens payment detail', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [
      const PaymentFeedItem(
        paymentId: 'pay-pending-1',
        stayId: 'stay-1',
        fullName: 'Aarav Patel',
        roomNumber: '101',
        amountPaise: 800000,
        paidOn: '2026-11-20',
        status: 'pending',
        methodCode: 'upi',
        methodLabel: 'UPI',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aarav Patel'));
    await tester.pumpAndSettle();

    expect(find.text('Payment detail for pay-pending-1'), findsOneWidget);
  });

  testWidgets('O9: Inline confirm button opens confirm sheet and confirms payment', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [
      const PaymentFeedItem(
        paymentId: 'pay-pending-1',
        stayId: 'stay-1',
        fullName: 'Aarav Patel',
        roomNumber: '101',
        amountPaise: 800000,
        paidOn: '2026-11-20',
        status: 'pending',
        methodCode: 'upi',
        methodLabel: 'UPI',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Confirm'));
    await tester.pumpAndSettle();

    // Confirm sheet opens
    expect(find.text('Mark as received'), findsWidgets);

    final markReceivedBtn = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(AppButton),
    );
    await tester.tap(markReceivedBtn);
    await tester.pumpAndSettle();

    expect(repo.confirmedPaymentId, 'pay-pending-1');
  });

  testWidgets('O9: Inline reject button opens reject sheet and rejects payment', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [
      const PaymentFeedItem(
        paymentId: 'pay-pending-1',
        stayId: 'stay-1',
        fullName: 'Aarav Patel',
        roomNumber: '101',
        amountPaise: 800000,
        paidOn: '2026-11-20',
        status: 'pending',
        methodCode: 'upi',
        methodLabel: 'UPI',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(find.text('Reject this payment?'), findsOneWidget);

    await tester.enterText(find.byType(AppTextField), 'Payment not found in bank');
    await tester.pumpAndSettle();

    final submitRejectBtn = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(AppButton),
    );
    await tester.tap(submitRejectBtn);
    await tester.pumpAndSettle();

    expect(repo.rejectedPaymentId, 'pay-pending-1');
    expect(repo.rejectedReason, 'Payment not found in bank');
  });

  testWidgets('O9: Recent tab displays empty state when no recent payments', (tester) async {
    final repo = MockOwnerRepo();
    repo.payments = [
      // Only pending payment
      const PaymentFeedItem(
        paymentId: 'pay-pending-1',
        stayId: 'stay-1',
        fullName: 'Aarav Patel',
        roomNumber: '101',
        amountPaise: 800000,
        paidOn: '2026-11-20',
        status: 'pending',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Switch to Recent tab
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    expect(find.text('No payments yet'), findsOneWidget);
    expect(find.text('Recorded and confirmed payments will appear here.'), findsOneWidget);
  });

  testWidgets('O9: Recent tab groups payments by day with correct icons, subtitles and chips', (tester) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final repo = MockOwnerRepo();
    repo.payments = [
      PaymentFeedItem(
        paymentId: 'pay-confirmed-today',
        stayId: 'stay-1',
        fullName: 'Kiran Kumar',
        roomNumber: '101',
        amountPaise: 850000,
        paidOn: todayStr,
        status: 'confirmed',
        methodCode: 'upi',
        methodLabel: 'UPI',
        payerAppLabel: 'Google Pay',
      ),
      PaymentFeedItem(
        paymentId: 'pay-reversed-yesterday',
        stayId: 'stay-2',
        fullName: 'Pooja Reddy',
        roomNumber: '102',
        amountPaise: 600000,
        paidOn: yesterdayStr,
        status: 'reversed',
        methodCode: 'bank',
        methodLabel: 'Bank transfer',
      ),
      const PaymentFeedItem(
        paymentId: 'pay-rejected-past',
        stayId: 'stay-3',
        fullName: 'Vikram Singh',
        amountPaise: 500000,
        paidOn: '2025-05-10',
        status: 'rejected',
        methodCode: 'cash',
        methodLabel: 'Cash',
      ),
    ];

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Switch to Recent tab
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    // Section headers: Today, Yesterday, 10 May 2025
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('10 May 2025'), findsOneWidget);

    // Subtitles
    expect(find.text('UPI, Google Pay, Room 101'), findsOneWidget);
    expect(find.text('Bank transfer, Room 102'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    // Chips: reversed and rejected show overdue chips; confirmed shows no chip
    expect(find.text('Reversed'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Confirmed'), findsNothing);

    // Tapping a row opens detail
    await tester.tap(find.text('Kiran Kumar'));
    await tester.pumpAndSettle();

    expect(find.text('Payment detail for pay-confirmed-today'), findsOneWidget);
  });

  testWidgets('O9: Error state renders retry button which refreshes on tap', (tester) async {
    final repo = MockOwnerRepo();
    repo.shouldThrow = true;

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);

    // Fix error and tap retry
    repo.shouldThrow = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing);
  });
}
