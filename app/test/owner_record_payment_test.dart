import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/app_top_bar.dart';
import 'package:app/core/widgets/money_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_record_payment_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  final GuestDetailBundle? bundle;
  final List<PaymentAccount> accounts;
  final List<PaymentMethod> methods;
  final List<UpiApp> upiApps;
  bool shouldThrowDuplicateUtr = false;
  Map<String, dynamic>? lastRecordedPayment;

  MockOwnerRepo({
    this.bundle,
    this.accounts = const [],
    this.methods = const [
      PaymentMethod(id: 1, code: 'cash', label: 'Cash'),
      PaymentMethod(id: 2, code: 'upi', label: 'UPI'),
      PaymentMethod(id: 3, code: 'bank_transfer', label: 'Bank transfer'),
      PaymentMethod(id: 4, code: 'cheque', label: 'Cheque'),
    ],
    this.upiApps = const [
      UpiApp(id: 1, code: 'gpay', label: 'Google Pay'),
      UpiApp(id: 2, code: 'phonepe', label: 'PhonePe'),
    ],
  });

  @override
  Future<GuestDetailBundle?> getGuestDetailBundle(String stayId) async => bundle;

  @override
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async => accounts;

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => methods;

  @override
  Future<List<UpiApp>> getUpiApps() async => upiApps;

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
  }) async {
    if (shouldThrowDuplicateUtr) {
      throw const DuplicateUtrException('This UTR is already recorded for another payment');
    }
    lastRecordedPayment = {
      'stayId': stayId,
      'amountPaise': amountPaise,
      'methodCode': methodCode,
      'paidOn': paidOn,
      'accountId': accountId,
      'note': note,
      'payerAppCode': payerAppCode,
      'utr': utr,
    };
    return 'pay-rec-123';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapScreen({
  required MockOwnerRepo repo,
  String stayId = 'stay-1',
  GoRouter? router,
}) {
  final testRouter = router ??
      GoRouter(
        initialLocation: '/owner/guests/$stayId/pay',
        routes: [
          GoRoute(
            path: '/owner/guests/:stayId/pay',
            builder: (context, state) => OwnerRecordPaymentScreen(
              stayId: state.pathParameters['stayId'] ?? stayId,
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
      ownerRepositoryProvider.overrideWithValue(repo),
      activePgProvider.overrideWithValue(
        const AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: testRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

GuestDetailBundle _createTestBundle({
  int dueNowPaise = 650000,
  int outstandingPaise = 1300000,
  String roomNumber = '101',
  String bedLabel = 'A',
}) {
  return GuestDetailBundle(
    guest: GuestListItem(
      stayId: 'stay-1',
      pgId: 'pg-1',
      pgName: 'Sunrise PG',
      personId: 'p-1',
      fullName: 'Rahul Sharma',
      phone: '+919876543210',
      stayStatus: 'open',
      joinDate: '2026-06-01',
      billingDay: 1,
      roomNumber: roomNumber,
      bedLabel: bedLabel,
      monthlyRentPaise: 650000,
      dueNowPaise: dueNowPaise,
      outstandingPaise: outstandingPaise,
      attentionState: 'due',
    ),
    charges: const [],
    payments: const [],
  );
}

void main() {
  testWidgets('O7 renders guest name, room, amount field and payment methods',
      (tester) async {
    final repo = MockOwnerRepo(bundle: _createTestBundle());
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppTopBar, 'Record payment'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Record payment'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Room 101, bed A'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('Cheque'), findsOneWidget);
    expect(find.text('Due now ₹6,500'), findsOneWidget);
    expect(find.text('All unpaid ₹13,000'), findsOneWidget);
  });

  testWidgets('O7 quick buttons change amount and show advance note when exceeding balance',
      (tester) async {
    final repo = MockOwnerRepo(bundle: _createTestBundle());
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Default amount was dueNow: 6,500
    expect(find.text('6,500'), findsOneWidget);

    // Tap All unpaid
    await tester.tap(find.text('All unpaid ₹13,000'));
    await tester.pumpAndSettle();

    expect(find.text('13,000'), findsOneWidget);
    expect(find.text('Anything above what is unpaid is kept as advance.'), findsNothing);

    // Enter an amount higher than outstanding
    await tester.enterText(find.byType(MoneyField), '15000');
    await tester.pumpAndSettle();

    expect(find.text('Anything above what is unpaid is kept as advance.'), findsOneWidget);
  });

  testWidgets('O7 method switching shows UPI fields and account selection',
      (tester) async {
    final repo = MockOwnerRepo(
      bundle: _createTestBundle(),
      accounts: const [
        PaymentAccount(
          id: 'acc-1',
          pgId: 'pg-1',
          nickname: 'HDFC Current',
          kind: 'bank',
          bankName: 'HDFC',
          accountLast4: '4321',
          isDefault: true,
          isActive: true,
        ),
      ],
    );
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Cash mode: no Received in or UTR
    expect(find.text('Received in'), findsNothing);
    expect(find.text('UTR (optional)'), findsNothing);

    // Switch to UPI
    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();

    expect(find.text('Received in'), findsOneWidget);
    expect(find.text('Paid using (optional)'), findsOneWidget);
    expect(find.text('UTR (optional)'), findsOneWidget);

    // Switch to Bank transfer: Received in is visible, UTR is not
    await tester.tap(find.text('Bank transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Received in'), findsOneWidget);
    expect(find.text('UTR (optional)'), findsNothing);
  });

  testWidgets('O7 validates UTR and submits payment successfully to receipt',
      (tester) async {
    final repo = MockOwnerRepo(bundle: _createTestBundle());
    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Switch to UPI
    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();

    // Enter short UTR (less than 6 chars)
    final utrFinder = find.widgetWithText(AppTextField, 'UTR (optional)');
    await tester.enterText(utrFinder, '123');
    await tester.pumpAndSettle();

    // Tap record payment
    await tester.tap(find.widgetWithText(AppButton, 'Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('Enter 6 to 22 letters or digits.'), findsOneWidget);

    // Enter valid UTR
    await tester.enterText(utrFinder, 'UPI123456789');
    await tester.pumpAndSettle();
    expect(find.text('Enter 6 to 22 letters or digits.'), findsNothing);

    // Tap record payment again
    await tester.tap(find.widgetWithText(AppButton, 'Record payment'));
    await tester.pumpAndSettle();

    expect(repo.lastRecordedPayment, isNotNull);
    expect(repo.lastRecordedPayment!['amountPaise'], 650000);
    expect(repo.lastRecordedPayment!['methodCode'], 'upi');
    expect(repo.lastRecordedPayment!['utr'], 'UPI123456789');

    // Navigated to receipt
    expect(find.text('Receipt page for pay-rec-123'), findsOneWidget);
  });

  testWidgets('O7 shows duplicate UTR exception message from database',
      (tester) async {
    final repo = MockOwnerRepo(bundle: _createTestBundle());
    repo.shouldThrowDuplicateUtr = true;

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();

    final utrFinder = find.widgetWithText(AppTextField, 'UTR (optional)');
    await tester.enterText(utrFinder, 'DUPLICATE123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('This UTR is already recorded for another payment'), findsOneWidget);
  });
}
