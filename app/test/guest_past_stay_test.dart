import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/features/guest/domain/guest_home_bundle.dart';
import 'package:app/features/guest/domain/guest_repository.dart';
import 'package:app/features/guest/domain/guest_stay_bundle.dart';
import 'package:app/features/guest/presentation/providers/guest_provider.dart';
import 'package:app/features/guest/presentation/screens/guest_past_stay_screen.dart';
import 'package:app/features/owner/domain/charge_balance.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/payment_feed_item.dart';
import 'package:app/features/owner/domain/payment_method.dart';
import 'package:app/features/owner/domain/upi_app.dart';

class MockGuestPastStayRepo implements GuestRepository {
  GuestStayBundle stayBundle;
  bool shouldThrow;

  MockGuestPastStayRepo({
    this.stayBundle = const GuestStayBundle(),
    this.shouldThrow = false,
  });

  @override
  Future<GuestHomeBundle> getGuestHomeData() async => const GuestHomeBundle();

  @override
  Future<GuestListItem?> getStay(String stayId) async => stayBundle.stay;

  @override
  Future<GuestStayBundle> getStayDetails(String stayId) async {
    if (shouldThrow) {
      throw Exception('Failed to load stay details');
    }
    return stayBundle;
  }

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
      'report-1';
}

GuestListItem _createSampleStay({
  String stayId = 'stay-past-1',
  String pgId = 'pg-1',
  String pgName = 'Sunrise Living',
  String joinDate = '2025-06-01',
  String? leaveDate = '2025-12-31',
  String? roomNumber = '204',
  String? bedLabel = 'B',
  int outstandingPaise = 0,
}) {
  return GuestListItem(
    stayId: stayId,
    pgId: pgId,
    personId: 'person-1',
    phone: '+919876543210',
    stayStatus: 'vacated',
    attentionState: 'past',
    monthlyRentPaise: 800000,
    creditPaise: 0,
    billingDay: 1,
    joinDate: joinDate,
    leaveDate: leaveDate,
    pgName: pgName,
    roomNumber: roomNumber,
    bedLabel: bedLabel,
    outstandingPaise: outstandingPaise,
    overduePaise: outstandingPaise,
  );
}

Widget _wrapPastStayScreen({
  required MockGuestPastStayRepo repo,
  String stayId = 'stay-past-1',
  GoRouter? customRouter,
}) {
  final router = customRouter ??
      GoRouter(
        initialLocation: '/guest/stay/$stayId',
        routes: [
          GoRoute(
            path: '/guest/stay/:stayId',
            builder: (context, state) => GuestPastStayScreen(
              stayId: state.pathParameters['stayId'] ?? '',
            ),
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
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestPastStayScreen (G5)', () {
    testWidgets('Header sheet renders PG name, dates, room details, and tabs',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay(
        pgName: 'Sunrise Living',
        joinDate: '2025-06-01',
        leaveDate: '2025-12-31',
        roomNumber: '204',
        bedLabel: 'B',
      );

      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-1',
          stayId: 'stay-past-1',
          paidOn: '2025-12-05',
          amountPaise: 800000,
          methodCode: 'upi',
          methodLabel: 'UPI',
          status: 'confirmed',
          receiptId: 'rec-1',
        ),
      ];

      final charges = [
        const ChargeBalance(
          chargeId: 'chg-1',
          stayId: 'stay-past-1',
          dueDate: '2025-12-01',
          amountPaise: 800000,
          outstandingPaise: 0,
          status: 'paid',
          description: 'Rent December 2025',
        ),
      ];

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(
          stay: stay,
          payments: payments,
          charges: charges,
        ),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // Top bar title has PG name
      expect(find.text('Sunrise Living'), findsNWidgets(2)); // in top bar and header sheet

      // Dates subtitle
      expect(find.text('1 Jun 2025 to 31 Dec 2025'), findsOneWidget);

      // Room and bed
      expect(find.text('Room 204, bed B'), findsOneWidget);

      // No outstanding balance notice when outstandingPaise == 0
      expect(find.textContaining('unpaid. Please contact them.'), findsNothing);

      // Tabs: Payments and Charges
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Charges'), findsOneWidget);

      // Payment row is visible
      expect(find.text('Rent December 2025'), findsNothing); // that's in charges tab
      expect(find.text('₹8,000'), findsOneWidget);
    });

    testWidgets('Header sheet hides room details when roomNumber is null',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay(
        roomNumber: null,
        bedLabel: null,
      );

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Room'), findsNothing);
    });

    testWidgets('Header sheet shows noStayOwes notice when outstandingPaise > 0',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay(
        pgName: 'Serene Heights',
        outstandingPaise: 150000,
      );

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // noStayOwes notice
      expect(
        find.text('Serene Heights shows ₹1,500 unpaid. Please contact them.'),
        findsOneWidget,
      );
    });

    testWidgets('Payments tab: tapping receipt opens receipt route',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay();
      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-rec-1',
          stayId: 'stay-past-1',
          paidOn: '2025-11-05',
          amountPaise: 800000,
          methodCode: 'bank_transfer',
          methodLabel: 'Bank transfer',
          status: 'confirmed',
          receiptId: 'receipt-123',
        ),
      ];

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay, payments: payments),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // Tap payment row
      await tester.tap(find.text('₹8,000'));
      await tester.pumpAndSettle();

      // Should navigate to receipt page
      expect(find.text('Receipt page for pay-rec-1'), findsOneWidget);
    });

    testWidgets(
        'Payments tab: tapping payment without receipt opens status sheet without Report again button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay();
      final payments = [
        const PaymentFeedItem(
          paymentId: 'pay-rej-1',
          stayId: 'stay-past-1',
          paidOn: '2025-10-05',
          amountPaise: 800000,
          methodCode: 'upi',
          methodLabel: 'UPI',
          status: 'rejected',
          statusReason: 'Wrong UTR number provided',
        ),
      ];

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay, payments: payments),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // Tap rejected payment
      await tester.tap(find.text('Rejected'));
      await tester.pumpAndSettle();

      // Status sheet should show reason
      expect(
        find.text('Your owner said: Wrong UTR number provided'),
        findsOneWidget,
      );

      // Crucial constraint: NO report again / pay again button for ended stays!
      expect(find.text('Report it again'), findsNothing);
    });

    testWidgets('Empty states show for payments and charges tabs',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay();
      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(
          stay: stay,
          payments: const [],
          charges: const [],
        ),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // Empty payments
      expect(find.text('No payments yet'), findsOneWidget);
      expect(
        find.text('Payments you make or report will show here.'),
        findsOneWidget,
      );

      // Switch to Charges tab
      await tester.tap(find.text('Charges'));
      await tester.pumpAndSettle();

      // Empty charges
      expect(find.text('No charges yet'), findsOneWidget);
    });

    testWidgets('Charges tab renders grouped charges with status chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay();
      final charges = [
        const ChargeBalance(
          chargeId: 'c1',
          stayId: 'stay-past-1',
          dueDate: '2025-11-01',
          amountPaise: 800000,
          outstandingPaise: 0,
          status: 'paid',
          description: 'November Rent',
        ),
        const ChargeBalance(
          chargeId: 'c2',
          stayId: 'stay-past-1',
          dueDate: '2025-10-01',
          amountPaise: 800000,
          outstandingPaise: 800000,
          status: 'overdue',
          description: 'October Rent',
        ),
      ];

      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay, charges: charges),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // Switch to Charges tab
      await tester.tap(find.text('Charges'));
      await tester.pumpAndSettle();

      expect(find.text('November Rent'), findsOneWidget);
      expect(find.text('October Rent'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('Read-only: no pay or report buttons anywhere on the screen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stay = _createSampleStay(outstandingPaise: 500000);
      final repo = MockGuestPastStayRepo(
        stayBundle: GuestStayBundle(stay: stay),
      );

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      // No pay buttons or already paid buttons
      expect(find.textContaining('Pay ₹'), findsNothing);
      expect(find.text("Tell your owner you've paid"), findsNothing);
      expect(find.text("I've already paid"), findsNothing);
      expect(find.text('Report it again'), findsNothing);
    });

    testWidgets('Error state allows retry', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockGuestPastStayRepo(shouldThrow: true);

      await tester.pumpWidget(_wrapPastStayScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);

      // Fix error and retry
      repo.shouldThrow = false;
      repo.stayBundle = GuestStayBundle(stay: _createSampleStay());

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Living'), findsNWidgets(2));
    });
  });
}

