import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/features/guest/domain/guest_home_bundle.dart';
import 'package:app/features/guest/domain/guest_repository.dart';
import 'package:app/features/guest/presentation/providers/guest_provider.dart';
import 'package:app/features/guest/presentation/screens/guest_history_screen.dart';
import 'package:app/features/owner/domain/charge_balance.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/payment_feed_item.dart';
import 'package:app/features/owner/domain/payment_method.dart';
import 'package:app/features/owner/domain/upi_app.dart';

class MockGuestHistoryRepo implements GuestRepository {
  GuestHomeBundle bundle;

  MockGuestHistoryRepo({
    this.bundle = const GuestHomeBundle(),
  });

  @override
  Future<GuestHomeBundle> getGuestHomeData() async => bundle;

  @override
  Future<GuestListItem?> getStay(String stayId) async => bundle.currentStay;

  @override
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId) async => [];

  @override
  Future<List<PaymentAccount>> getActiveBankAccounts(String pgId) async => [];

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => [
        const PaymentMethod(id: 1, code: 'cash', label: 'Cash'),
        const PaymentMethod(id: 2, code: 'upi', label: 'UPI'),
      ];

  @override
  Future<List<UpiApp>> getUpiApps() async => [];

  @override
  Future<String> reportPayment({
    required String stayId,
    required int amountPaise,
    required String methodCode,
    DateTime? paidOn,
    String? accountId,
    String? payerAppCode,
    String? payerPhone,
    String? utr,
    String? note,
    String? screenshotFileId,
  }) async =>
      'reported-pay-1';
}

GuestListItem _createTestStay({
  String stayId = 'stay-1',
  String pgId = 'pg-1',
  String pgName = 'Green Park PG',
  String stayStatus = 'active',
  String joinDate = '2026-01-01',
  String? leaveDate,
}) {
  return GuestListItem(
    stayId: stayId,
    personId: 'p-1',
    pgId: pgId,
    fullName: 'Rahul Sharma',
    phone: '+919876543210',
    stayStatus: stayStatus,
    attentionState: 'paid',
    monthlyRentPaise: 650000,
    creditPaise: 0,
    billingDay: 5,
    joinDate: joinDate,
    leaveDate: leaveDate,
    pgName: pgName,
    overduePaise: 0,
    dueNowPaise: 0,
    nextDuePaise: 650000,
  );
}

Widget _wrapHistoryScreen({
  required MockGuestHistoryRepo repo,
  GoRouter? customRouter,
}) {
  final router = customRouter ??
      GoRouter(
        initialLocation: '/guest/history',
        routes: [
          GoRoute(
            path: '/guest/history',
            builder: (context, state) => const GuestHistoryScreen(),
          ),
          GoRoute(
            path: '/receipt/:paymentId',
            builder: (context, state) => Scaffold(
              body: Text('Receipt page for ${state.pathParameters['paymentId']}'),
            ),
          ),
          GoRoute(
            path: '/guest/stay/:stayId',
            builder: (context, state) => Scaffold(
              body: Text('Past stay page for ${state.pathParameters['stayId']}'),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      guestRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestHistoryScreen (G4)', () {
    testWidgets('Renders top bar, tabs, and payments grouped by month',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-1',
          stayId: 'stay-1',
          amountPaise: 650000,
          paidOn: '2026-11-12',
          status: 'confirmed',
          methodCode: 'upi',
          methodLabel: 'UPI',
          payerAppLabel: 'Google Pay',
          receiptId: 'rcpt-1',
        ),
        const PaymentFeedItem(
          paymentId: 'pay-2',
          stayId: 'stay-1',
          amountPaise: 650000,
          paidOn: '2026-10-10',
          status: 'confirmed',
          methodCode: 'cash',
          methodLabel: 'Cash',
          receiptId: 'rcpt-2',
        ),
      ];

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          payments: payments,
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      // Top bar title
      expect(find.text('History'), findsOneWidget);

      // UnderlineTabs
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Charges'), findsOneWidget);

      // Grouped by month
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      // Payment 1
      expect(find.text('Payment, UPI, Google Pay'), findsOneWidget);
      expect(find.text('12 Nov 2026'), findsOneWidget);
      expect(find.text('₹6,500'), findsNWidgets(2));

      // Payment 2
      expect(find.text('Payment, Cash'), findsOneWidget);
      expect(find.text('10 Oct 2026'), findsOneWidget);

      // Tapping payment with receipt opens receipt
      await tester.tap(find.text('Payment, UPI, Google Pay'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt page for pay-1'), findsOneWidget);
    });

    testWidgets('Tapping payment without receipt opens Payment Status Sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-pending',
          stayId: 'stay-1',
          amountPaise: 650000,
          paidOn: '2026-11-20',
          status: 'pending',
          methodCode: 'upi',
          methodLabel: 'UPI',
          createdAt: '2026-11-20T10:30:00Z',
        ),
      ];

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          payments: payments,
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      // Pending chip in row
      expect(find.text('Pending'), findsOneWidget);

      // Tap to open sheet
      await tester.tap(find.text('Payment, UPI'));
      await tester.pumpAndSettle();

      // Payment Status Sheet content
      expect(find.text('₹6,500'), findsNWidgets(2)); // row + sheet display
      expect(find.text('Method'), findsOneWidget);
      expect(find.text('Paid on'), findsOneWidget);
      expect(find.text('Reported on'), findsOneWidget);
      expect(find.text('20 Nov 2026'), findsNWidgets(3)); // subtitle, paid on, reported on
      expect(
        find.text('Waiting for your owner to confirm.'),
        findsOneWidget,
      );
    });

    testWidgets('Rejected payment shows rejection reason and "Report it again" button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-rejected',
          stayId: 'stay-1',
          amountPaise: 650000,
          paidOn: '2026-11-18',
          status: 'rejected',
          statusReason: 'Amount not received in account',
          methodCode: 'bank_transfer',
          methodLabel: 'Bank transfer',
          createdAt: '2026-11-18T12:00:00Z',
        ),
      ];

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          payments: payments,
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      // Rejected chip in row
      expect(find.text('Rejected'), findsOneWidget);

      await tester.tap(find.text('Payment, Bank transfer'));
      await tester.pumpAndSettle();

      // Sheet displays rejection reason and retry button
      expect(
        find.text('Your owner said: Amount not received in account'),
        findsOneWidget,
      );
      expect(find.text('Report it again'), findsOneWidget);

      // Tap Report it again opens G3 Variant B
      await tester.tap(find.text('Report it again'));
      await tester.pumpAndSettle();

      expect(find.text("Tell your owner you've paid"), findsOneWidget);
    });

    testWidgets('Previous stays listed at bottom of Payments tab and opens G5',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final previousStay = _createTestStay(
        stayId: 'stay-past-1',
        pgName: 'Sunshine PG',
        stayStatus: 'vacated',
        joinDate: '2025-06-01',
        leaveDate: '2025-12-31',
      );

      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-1',
          stayId: 'stay-1',
          amountPaise: 650000,
          paidOn: '2026-11-12',
          status: 'confirmed',
          receiptId: 'rcpt-1',
        ),
      ];

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          previousStays: [previousStay],
          payments: payments,
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Previous stays'), findsOneWidget);
      expect(find.text('Sunshine PG'), findsOneWidget);
      expect(find.text('1 Jun 2025 to 31 Dec 2025'), findsOneWidget);

      await tester.tap(find.text('Sunshine PG'));
      await tester.pumpAndSettle();

      expect(find.text('Past stay page for stay-past-1'), findsOneWidget);
    });

    testWidgets('Charges tab displays charges grouped by month with status chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final charges = [
        const ChargeBalance(
          chargeId: 'chg-1',
          stayId: 'stay-1',
          description: 'Rent for Nov 2026',
          dueDate: '2026-11-05',
          amountPaise: 650000,
          outstandingPaise: 650000,
          status: 'overdue',
        ),
        const ChargeBalance(
          chargeId: 'chg-2',
          stayId: 'stay-1',
          description: 'Maintenance fee',
          dueDate: '2026-11-15',
          amountPaise: 50000,
          outstandingPaise: 0,
          status: 'paid',
        ),
        const ChargeBalance(
          chargeId: 'chg-3',
          stayId: 'stay-1',
          description: 'Rent for Oct 2026',
          dueDate: '2026-10-05',
          amountPaise: 650000,
          outstandingPaise: 200000,
          status: 'partial',
        ),
      ];

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          charges: charges,
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      // Switch to Charges tab
      await tester.tap(find.text('Charges'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      expect(find.text('Rent for Nov 2026'), findsOneWidget);
      expect(find.text('due 5 Nov 2026'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      expect(find.text('Maintenance fee'), findsOneWidget);
      expect(find.text('due 15 Nov 2026'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);

      expect(find.text('Rent for Oct 2026'), findsOneWidget);
      expect(find.text('due 5 Oct 2026'), findsOneWidget);
      expect(find.text('Part-paid'), findsOneWidget);
    });

    testWidgets('Empty states for payments and charges tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stay = _createTestStay();
      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: stay,
          payments: const [],
          charges: const [],
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      // Payments tab empty state
      expect(find.text('No payments yet'), findsOneWidget);
      expect(
        find.text('Payments you make or report will show here.'),
        findsOneWidget,
      );

      // Switch to Charges tab
      await tester.tap(find.text('Charges'));
      await tester.pumpAndSettle();

      // Charges tab empty state
      expect(find.text('No charges yet'), findsOneWidget);
    });

    testWidgets('Past stay displays notice at top of history', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pastStay = _createTestStay(
        stayId: 'stay-past-1',
        pgName: 'Green Park PG',
        stayStatus: 'vacated',
      );

      final repo = MockGuestHistoryRepo(
        bundle: GuestHomeBundle(
          currentStay: null,
          latestPastStay: pastStay,
          payments: const [],
          charges: const [],
        ),
      );

      await tester.pumpWidget(_wrapHistoryScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('This is your stay at Green Park PG, which has ended.'),
        findsOneWidget,
      );
    });
  });
}
