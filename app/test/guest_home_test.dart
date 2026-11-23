import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/features/guest/domain/guest_home_bundle.dart';
import 'package:app/features/guest/domain/guest_repository.dart';
import 'package:app/features/guest/presentation/providers/guest_provider.dart';
import 'package:app/features/guest/presentation/screens/guest_home_screen.dart';
import 'package:app/features/owner/domain/charge_balance.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/payment_feed_item.dart';
import 'package:app/features/owner/domain/payment_method.dart';
import 'package:app/features/owner/domain/upi_app.dart';

class MockGuestRepo implements GuestRepository {
  GuestHomeBundle bundle;

  MockGuestRepo({this.bundle = const GuestHomeBundle()});

  @override
  Future<GuestHomeBundle> getGuestHomeData() async => bundle;

  @override
  Future<GuestListItem?> getStay(String stayId) async =>
      bundle.currentStay ?? bundle.latestPastStay;

  @override
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId) async =>
      const [];

  @override
  Future<List<PaymentAccount>> getActiveBankAccounts(String pgId) async =>
      const [];

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => const [];

  @override
  Future<List<UpiApp>> getUpiApps() async => const [];

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
      'pay-reported';
}

Widget _wrapGuestHomeScreen({
  required MockGuestRepo repo,
  GoRouter? router,
}) {
  final testRouter = router ??
      GoRouter(
        initialLocation: '/guest/home',
        routes: [
          GoRoute(
            path: '/guest/home',
            builder: (context, state) => const GuestHomeScreen(),
          ),
          GoRoute(
            path: '/receipt/:paymentId',
            builder: (context, state) => Scaffold(
              body: Text('Receipt page for ${state.pathParameters['paymentId']}'),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      guestRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: testRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

GuestListItem _createTestStay({
  String stayId = 'stay-1',
  String pgName = 'Green Park PG',
  String? pgContactPhone = '+919876543210',
  int monthlyRentPaise = 650000,
  int billingDay = 12,
  int creditPaise = 0,
  int overduePaise = 0,
  int? dueNowPaise,
  int? nextDuePaise,
  int pendingVerificationPaise = 0,
  String? oldestUnpaidDueDate,
  String? nextDueDate,
  String roomNumber = '101',
  String bedLabel = 'A',
  String stayStatus = 'active',
  int outstandingPaise = 0,
}) {
  return GuestListItem(
    stayId: stayId,
    pgId: 'pg-1',
    pgName: pgName,
    pgContactPhone: pgContactPhone,
    personId: 'person-1',
    fullName: 'Test Guest',
    phone: '+919876543211',
    stayStatus: stayStatus,
    joinDate: '2026-06-01',
    billingDay: billingDay,
    roomNumber: roomNumber,
    bedLabel: bedLabel,
    monthlyRentPaise: monthlyRentPaise,
    creditPaise: creditPaise,
    overduePaise: overduePaise,
    dueNowPaise: dueNowPaise,
    nextDuePaise: nextDuePaise,
    pendingVerificationPaise: pendingVerificationPaise,
    oldestUnpaidDueDate: oldestUnpaidDueDate,
    nextDueDate: nextDueDate,
    outstandingPaise: outstandingPaise,
    attentionState: overduePaise > 0
        ? 'overdue'
        : (dueNowPaise != null && dueNowPaise > 0)
            ? 'due'
            : 'paid',
  );
}

void main() {
  testWidgets('G1 displays overdue state when overduePaise > 0', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final stay = _createTestStay(
      overduePaise: 650000,
      dueNowPaise: 650000,
      oldestUnpaidDueDate: '2026-10-27',
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(currentStay: stay),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Green Park PG'), findsOneWidget);
    expect(find.text('Overdue since 27 Oct 2026'), findsOneWidget);
    expect(find.text('₹6,500'), findsWidgets);
    expect(find.text('Your stay'), findsOneWidget);
    expect(find.text('Monthly rent'), findsOneWidget);
    expect(find.text('Rent due on'), findsOneWidget);
    expect(find.text('Day 12 of every month'), findsOneWidget);
    expect(find.text('Room 101, bed A'), findsOneWidget);
    expect(find.text('Your PG'), findsOneWidget);
    expect(find.text('Call Green Park PG'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
  });

  testWidgets('G1 displays due now state when dueNowPaise > 0 and overdue is 0', (tester) async {
    final stay = _createTestStay(
      overduePaise: 0,
      dueNowPaise: 650000,
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(currentStay: stay),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Due now'), findsOneWidget);
    expect(find.text('₹6,500'), findsWidgets);
  });

  testWidgets('G1 displays next due state when nextDuePaise > 0 and dueNow is 0', (tester) async {
    final stay = _createTestStay(
      overduePaise: 0,
      dueNowPaise: 0,
      nextDuePaise: 650000,
      nextDueDate: '2026-12-12',
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(currentStay: stay),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Next rent due 12 Dec 2026'), findsOneWidget);
    expect(find.text('₹6,500'), findsWidgets);
  });

  testWidgets('G1 displays paid-up state when no dues or upcoming dues', (tester) async {
    final stay = _createTestStay(
      overduePaise: 0,
      dueNowPaise: 0,
      nextDuePaise: 0,
      creditPaise: 50000,
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(currentStay: stay),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text("You're all paid up"), findsOneWidget);
    expect(find.text("Your next rent will show here before it's due."), findsOneWidget);
    expect(find.text('Advance balance'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
  });

  testWidgets('G1 displays waiting notice when pending verification paise > 0', (tester) async {
    final stay = _createTestStay(
      dueNowPaise: 650000,
      pendingVerificationPaise: 250000,
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(currentStay: stay),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('₹2,500 reported. Waiting for your owner to confirm.'), findsOneWidget);
  });

  testWidgets('G1 displays recent activity merged and navigates to receipt on tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);

    final stay = _createTestStay(dueNowPaise: 650000);
    final charges = [
      const ChargeBalance(
        chargeId: 'c-1',
        stayId: 'stay-1',
        description: 'Rent for Nov 2026',
        amountPaise: 650000,
        outstandingPaise: 650000,
        paidPaise: 0,
        dueDate: '2026-11-12',
        status: 'due',
      ),
    ];
    final payments = [
      const PaymentFeedItem(
        paymentId: 'pay-1',
        stayId: 'stay-1',
        amountPaise: 650000,
        paidOn: '2026-10-12',
        status: 'confirmed',
        methodCode: 'upi',
        methodLabel: 'UPI',
        payerAppLabel: 'PhonePe',
        receiptId: 'rc-1',
      ),
    ];

    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(
        currentStay: stay,
        charges: charges,
        payments: payments,
      ),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Rent for Nov 2026'), findsOneWidget);
    expect(find.text('due 12 Nov 2026'), findsOneWidget);
    expect(find.text('Payment, UPI, PhonePe'), findsOneWidget);
    expect(find.text('12 Oct 2026'), findsOneWidget);

    // Tap payment row to open receipt
    await tester.tap(find.text('Payment, UPI, PhonePe'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt page for pay-1'), findsOneWidget);
  });

  testWidgets('G1 empty state when guest has no current stay, shows past stay owes notice', (tester) async {
    final pastStay = _createTestStay(
      stayId: 'stay-past',
      pgName: 'Sunrise PG',
      stayStatus: 'vacated',
      outstandingPaise: 300000,
      pgContactPhone: '+919876543210',
    );
    final repo = MockGuestRepo(
      bundle: GuestHomeBundle(
        currentStay: null,
        latestPastStay: pastStay,
      ),
    );

    await tester.pumpWidget(_wrapGuestHomeScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('No current stay'), findsOneWidget);
    expect(find.text("You've left Sunrise PG. Your past payments are in History."), findsOneWidget);
    expect(find.text('Sunrise PG shows ₹3,000 unpaid. Please contact them.'), findsOneWidget);
    expect(find.text('Call Sunrise PG'), findsOneWidget);
  });
}
