import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/features/guest/domain/guest_home_bundle.dart';
import 'package:app/features/guest/domain/guest_repository.dart';
import 'package:app/features/guest/presentation/providers/guest_provider.dart';
import 'package:app/features/guest/presentation/screens/guest_home_screen.dart';
import 'package:app/features/guest/presentation/screens/guest_pay_rent_screen.dart';
import 'package:app/features/guest/presentation/widgets/guest_report_payment_sheet.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/payment_method.dart';
import 'package:app/features/owner/domain/upi_app.dart';

class MockGuestReportRepo implements GuestRepository {
  GuestListItem? stay;
  List<PaymentAccount> upiAccounts;
  List<PaymentAccount> bankAccounts;
  List<PaymentMethod> paymentMethods;
  List<UpiApp> upiApps;
  GuestHomeBundle bundle;

  // Track recorded calls
  Map<String, dynamic>? lastReportCall;
  Exception? reportErrorToThrow;

  MockGuestReportRepo({
    this.stay,
    this.upiAccounts = const [],
    this.bankAccounts = const [],
    this.paymentMethods = const [
      PaymentMethod(id: 1, code: 'cash', label: 'Cash'),
      PaymentMethod(id: 2, code: 'upi', label: 'UPI'),
      PaymentMethod(id: 3, code: 'bank_transfer', label: 'Bank transfer'),
      PaymentMethod(id: 4, code: 'cheque', label: 'Cheque'),
    ],
    this.upiApps = const [
      UpiApp(id: 1, code: 'gpay', label: 'Google Pay'),
      UpiApp(id: 2, code: 'phonepe', label: 'PhonePe'),
      UpiApp(id: 3, code: 'paytm', label: 'Paytm'),
    ],
    this.bundle = const GuestHomeBundle(),
    this.reportErrorToThrow,
  });

  @override
  Future<GuestHomeBundle> getGuestHomeData() async => bundle;

  @override
  Future<GuestListItem?> getStay(String stayId) async => stay;

  @override
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId) async =>
      upiAccounts;

  @override
  Future<List<PaymentAccount>> getActiveBankAccounts(String pgId) async =>
      bankAccounts;

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async => paymentMethods;

  @override
  Future<List<UpiApp>> getUpiApps() async => upiApps;

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
  }) async {
    if (reportErrorToThrow != null) {
      throw reportErrorToThrow!;
    }
    lastReportCall = {
      'stayId': stayId,
      'amountPaise': amountPaise,
      'methodCode': methodCode,
      'paidOn': paidOn,
      'accountId': accountId,
      'payerAppCode': payerAppCode,
      'payerPhone': payerPhone,
      'utr': utr,
      'note': note,
      'screenshotFileId': screenshotFileId,
    };
    return 'pay-uuid-1';
  }
}

PaymentAccount _createTestUpiAccount({
  String id = 'acc-upi-1',
  String pgId = 'pg-1',
  String nickname = 'PG Main UPI',
  String upiVpa = 'greenpark@okaxis',
  bool isDefault = true,
}) {
  return PaymentAccount(
    id: id,
    pgId: pgId,
    nickname: nickname,
    kind: 'upi',
    upiVpa: upiVpa,
    isDefault: isDefault,
    isActive: true,
  );
}

PaymentAccount _createTestBankAccount({
  String id = 'acc-bank-1',
  String pgId = 'pg-1',
  String nickname = 'HDFC Current',
  String bankName = 'HDFC Bank',
  String accountLast4 = '4321',
  bool isDefault = false,
}) {
  return PaymentAccount(
    id: id,
    pgId: pgId,
    nickname: nickname,
    kind: 'bank',
    bankName: bankName,
    accountLast4: accountLast4,
    isDefault: isDefault,
    isActive: true,
  );
}

GuestListItem _createTestStay({
  String stayId = 'stay-1',
  String pgId = 'pg-1',
  String pgName = 'Green Park PG',
  int overduePaise = 0,
  int dueNowPaise = 650000,
  int nextDuePaise = 650000,
}) {
  return GuestListItem(
    stayId: stayId,
    personId: 'p-1',
    pgId: pgId,
    fullName: 'Rahul Sharma',
    phone: '+919876543210',
    stayStatus: 'active',
    attentionState: 'due',
    monthlyRentPaise: 650000,
    creditPaise: 0,
    billingDay: 5,
    joinDate: '2026-01-01',
    pgName: pgName,
    overduePaise: overduePaise,
    dueNowPaise: dueNowPaise,
    nextDuePaise: nextDuePaise,
  );
}

Widget _wrapSheetLauncher({
  required MockGuestReportRepo repo,
  required Future<void> Function(BuildContext context) onLaunch,
}) {
  return ProviderScope(
    overrides: [
      guestRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onLaunch(context),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestReportPaymentSheet (G3) - Variant A', () {
    testWidgets('Renders Variant A elements and toggles collapsible details',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockGuestReportRepo();
      final upiAccount = _createTestUpiAccount();

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantA(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            amountPaise: 650000,
            upiAccount: upiAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Did the payment go through?'), findsOneWidget);
      expect(find.text('₹6,500 to PG Main UPI'), findsOneWidget);
      expect(find.text('Add details (optional)'), findsOneWidget);
      expect(find.text("Yes, I've paid"), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);

      // Collapsed by default
      expect(find.text('Paid using'), findsNothing);
      expect(find.text('UTR or reference'), findsNothing);

      // Tap to expand details
      await tester.tap(find.text('Add details (optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Paid using'), findsOneWidget);
      expect(find.text('UTR or reference'), findsOneWidget);
      expect(find.text('Paid from number'), findsOneWidget);

      // Select UPI app
      await tester.tap(find.text('Select app'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Google Pay'), findsOneWidget);
      await tester.tap(find.text('Google Pay'));
      await tester.pumpAndSettle();

      expect(find.text('Google Pay'), findsOneWidget);

      // Tap Yes, I've paid
      await tester.tap(find.text("Yes, I've paid"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.lastReportCall, isNotNull);
      expect(repo.lastReportCall!['stayId'], 'stay-1');
      expect(repo.lastReportCall!['amountPaise'], 650000);
      expect(repo.lastReportCall!['methodCode'], 'upi');
      expect(repo.lastReportCall!['accountId'], 'acc-upi-1');
      expect(repo.lastReportCall!['payerAppCode'], 'gpay');
      expect(
        find.text("Sent to your owner. You'll get a receipt once they confirm."),
        findsOneWidget,
      );
    });

    testWidgets('UTR length validation in Variant A', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockGuestReportRepo();
      final upiAccount = _createTestUpiAccount();

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantA(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            amountPaise: 650000,
            upiAccount: upiAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add details (optional)'));
      await tester.pumpAndSettle();

      // Enter short UTR (less than 6 chars)
      await tester.ensureVisible(find.widgetWithText(AppTextField, 'UTR or reference'));
      await tester.enterText(
        find.widgetWithText(AppTextField, 'UTR or reference'),
        '123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Yes, I've paid"));
      await tester.pumpAndSettle();

      expect(find.text('Enter 6 to 22 letters or numbers'), findsOneWidget);
      expect(repo.lastReportCall, isNull);
    });

    testWidgets('Database duplicate UTR error (23505) shows under UTR field',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockGuestReportRepo(
        reportErrorToThrow: const PostgrestException(
          message: 'This UTR is already recorded for another payment',
          code: '23505',
        ),
      );
      final upiAccount = _createTestUpiAccount();

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantA(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            amountPaise: 650000,
            upiAccount: upiAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Yes, I've paid"));
      await tester.pumpAndSettle();

      expect(
        find.text('This UTR is already recorded for another payment'),
        findsOneWidget,
      );
    });

    testWidgets('Variant A "Not yet" closes without reporting', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockGuestReportRepo();
      final upiAccount = _createTestUpiAccount();

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantA(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            amountPaise: 650000,
            upiAccount: upiAccount,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();

      expect(repo.lastReportCall, isNull);
      expect(find.text('Did the payment go through?'), findsNothing);
    });
  });

  group('GuestReportPaymentSheet (G3) - Variant B', () {
    testWidgets('Renders Variant B fields with Cash default and submits',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockGuestReportRepo();

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantB(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            defaultAmountPaise: 650000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text("Tell your owner you've paid"), findsOneWidget);
      expect(find.text('6,500'), findsOneWidget);
      expect(find.text('How did you pay?'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Bank transfer'), findsOneWidget);
      // Cheque is excluded
      expect(find.text('Cheque'), findsNothing);

      // Default Cash: no Paid to account selector
      expect(find.text('Paid to'), findsNothing);

      // Submit cash
      await tester.ensureVisible(find.text('Send to owner'));
      await tester.tap(find.text('Send to owner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.lastReportCall, isNotNull);
      expect(repo.lastReportCall!['methodCode'], 'cash');
      expect(repo.lastReportCall!['amountPaise'], 650000);
      expect(repo.lastReportCall!['accountId'], isNull);
    });

    testWidgets('Switching to Bank transfer displays bank account selector',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bankAcc = _createTestBankAccount();
      final repo = MockGuestReportRepo(bankAccounts: [bankAcc]);

      await tester.pumpWidget(
        _wrapSheetLauncher(
          repo: repo,
          onLaunch: (context) => GuestReportPaymentSheet.showVariantB(
            context: context,
            stayId: 'stay-1',
            pgId: 'pg-1',
            defaultAmountPaise: 650000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bank transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Paid to'), findsOneWidget);
      expect(find.text('Not sure'), findsOneWidget);

      await tester.tap(find.text('Not sure'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('HDFC Current'), findsOneWidget);
      await tester.tap(find.text('HDFC Current'));
      await tester.pumpAndSettle();

      expect(find.text('HDFC Current'), findsOneWidget);

      await tester.ensureVisible(find.text('Send to owner'));
      await tester.tap(find.text('Send to owner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.lastReportCall!['methodCode'], 'bank_transfer');
      expect(repo.lastReportCall!['accountId'], 'acc-bank-1');
    });
  });

  group('G1 and G2 integration with G3', () {
    testWidgets('G1 "I\'ve already paid" button opens Variant B sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final stay = _createTestStay(dueNowPaise: 650000);
      final repo = MockGuestReportRepo(
        stay: stay,
        bundle: GuestHomeBundle(currentStay: stay),
      );

      final testRouter = GoRouter(
        initialLocation: '/guest/home',
        routes: [
          GoRoute(
            path: '/guest/home',
            builder: (context, state) => const GuestHomeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guestRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("I've already paid"), findsOneWidget);
      await tester.tap(find.text("I've already paid"));
      await tester.pumpAndSettle();

      expect(find.text("Tell your owner you've paid"), findsOneWidget);
    });

    testWidgets('G2 "I paid another way" button opens Variant B sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final stay = _createTestStay(dueNowPaise: 650000);
      final acc = _createTestUpiAccount();
      final repo = MockGuestReportRepo(
        stay: stay,
        upiAccounts: [acc],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guestRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GuestPayRentScreen(
              stayId: 'stay-1',
              initialAmountPaise: 650000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('I paid another way'), findsOneWidget);
      await tester.tap(find.text('I paid another way'));
      await tester.pumpAndSettle();

      expect(find.text("Tell your owner you've paid"), findsOneWidget);
    });
  });
}
