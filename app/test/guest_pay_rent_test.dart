import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/features/guest/domain/guest_home_bundle.dart';
import 'package:app/features/guest/domain/guest_repository.dart';
import 'package:app/features/guest/domain/guest_stay_bundle.dart';
import 'package:app/features/guest/presentation/providers/guest_provider.dart';
import 'package:app/features/guest/presentation/screens/guest_home_screen.dart';
import 'package:app/features/guest/presentation/screens/guest_pay_rent_screen.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/payment_method.dart';
import 'package:app/features/owner/domain/upi_app.dart';

class MockGuestPayRepo implements GuestRepository {
  GuestListItem? stay;
  List<PaymentAccount> upiAccounts;
  GuestHomeBundle bundle;

  MockGuestPayRepo({
    this.stay,
    this.upiAccounts = const [],
    this.bundle = const GuestHomeBundle(),
  });

  @override
  Future<GuestHomeBundle> getGuestHomeData() async => bundle;

  @override
  Future<GuestListItem?> getStay(String stayId) async => stay;

  @override
  Future<GuestStayBundle> getStayDetails(String stayId) async =>
      const GuestStayBundle();

  @override
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId) async =>
      upiAccounts;

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

PaymentAccount _createTestUpiAccount({
  String id = 'acc-1',
  String pgId = 'pg-1',
  String nickname = 'PG Main UPI',
  String upiVpa = 'greenpark@okaxis',
  String holderName = 'Green Park Living',
  bool isDefault = true,
}) {
  return PaymentAccount(
    id: id,
    pgId: pgId,
    nickname: nickname,
    kind: 'upi',
    upiVpa: upiVpa,
    holderName: holderName,
    isDefault: isDefault,
    isActive: true,
  );
}

Widget _wrapGuestPayRentScreen({
  required MockGuestPayRepo repo,
  String stayId = 'stay-1',
  int? initialAmountPaise,
  Future<bool> Function(Uri uri)? onLaunchUpi,
}) {
  return ProviderScope(
    overrides: [
      guestRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GuestPayRentScreen(
        stayId: stayId,
        initialAmountPaise: initialAmountPaise,
        onLaunchUpi: onLaunchUpi,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestPayRentScreen (G2)', () {
    testWidgets('Renders amount field and quick fill buttons initialized from stay',
        (tester) async {
      final stay = _createTestStay(dueNowPaise: 650000, nextDuePaise: 650000);
      final acc = _createTestUpiAccount();
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc]);

      await tester.pumpWidget(_wrapGuestPayRentScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.text('6,500'), findsOneWidget);
      expect(find.text('Due now ₹6,500'), findsOneWidget);
      expect(find.text('Next rent ₹6,500'), findsOneWidget);
      expect(find.text('Pay to'), findsOneWidget);
      expect(find.text('PG Main UPI'), findsOneWidget);
      expect(find.text('greenpark@okaxis'), findsOneWidget);
      expect(find.text('Pay with UPI app'), findsOneWidget);
    });

    testWidgets('Quick-fill buttons set the amount field', (tester) async {
      final stay = _createTestStay(dueNowPaise: 500000, nextDuePaise: 800000);
      final acc = _createTestUpiAccount();
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc]);

      await tester.pumpWidget(_wrapGuestPayRentScreen(
        repo: repo,
        initialAmountPaise: 500000,
      ));
      await tester.pumpAndSettle();

      expect(find.text('5,000'), findsOneWidget);

      await tester.tap(find.text('Next rent ₹8,000'));
      await tester.pumpAndSettle();

      expect(find.text('8,000'), findsOneWidget);
    });

    testWidgets('Copies UPI ID to clipboard and shows snackbar', (tester) async {
      final stay = _createTestStay();
      final acc = _createTestUpiAccount(upiVpa: 'testvpa@upi');
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc]);

      String? copiedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedClipboardText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(_wrapGuestPayRentScreen(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.copy));
      await tester.pumpAndSettle();

      expect(copiedClipboardText, 'testvpa@upi');
      expect(find.text('Copied.'), findsOneWidget);
    });

    testWidgets('Multiple UPI accounts allow switching via OptionSheet',
        (tester) async {
      final stay = _createTestStay();
      final acc1 = _createTestUpiAccount(
        id: 'acc-1',
        nickname: 'Primary UPI',
        upiVpa: 'primary@upi',
        isDefault: true,
      );
      final acc2 = _createTestUpiAccount(
        id: 'acc-2',
        nickname: 'Secondary UPI',
        upiVpa: 'secondary@upi',
        isDefault: false,
      );
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc1, acc2]);

      await tester.pumpWidget(_wrapGuestPayRentScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Primary UPI'), findsOneWidget);
      expect(find.text('Pay to a different account'), findsOneWidget);

      await tester.tap(find.text('Pay to a different account'));
      await tester.pumpAndSettle();

      expect(find.text('Secondary UPI'), findsOneWidget);
      await tester.tap(find.text('Secondary UPI'));
      await tester.pumpAndSettle();

      expect(find.text('Secondary UPI'), findsOneWidget);
      expect(find.text('secondary@upi'), findsOneWidget);
    });

    testWidgets('Empty state when no UPI account is present', (tester) async {
      final stay = _createTestStay();
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: []);

      await tester.pumpWidget(_wrapGuestPayRentScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text("Your PG owner hasn't added a payment account yet"),
        findsOneWidget,
      );
      expect(
        find.text(
            'Ask them to add one, or pay in cash or by bank transfer and tell them here.'),
        findsOneWidget,
      );

      // Primary button should be disabled (onPressed == null)
      final payBtnFinder = find.widgetWithText(AppButton, 'Pay with UPI app');
      expect(payBtnFinder, findsOneWidget);
      final payBtn = tester.widget<AppButton>(payBtnFinder);
      expect(payBtn.onPressed, isNull);
    });

    testWidgets('Pay with UPI app constructs correct UPI URI and triggers launcher',
        (tester) async {
      final stay = _createTestStay(dueNowPaise: 650000);
      final acc = _createTestUpiAccount(
        upiVpa: 'greenpark@okaxis',
        holderName: 'Green Park PG',
      );
      Uri? launchedUri;

      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc]);

      await tester.pumpWidget(_wrapGuestPayRentScreen(
        repo: repo,
        onLaunchUpi: (uri) async {
          launchedUri = uri;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay with UPI app'));
      await tester.pumpAndSettle();

      expect(launchedUri, isNotNull);
      expect(launchedUri!.scheme, 'upi');
      expect(launchedUri!.host, 'pay');
      expect(launchedUri!.queryParameters['pa'], 'greenpark@okaxis');
      expect(launchedUri!.queryParameters['pn'], 'Green Park PG');
      expect(launchedUri!.queryParameters['am'], '6500.00');
      expect(launchedUri!.queryParameters['cu'], 'INR');
      expect(launchedUri!.queryParameters['tn'], 'Rent');
    });

    testWidgets('Shows error snackbar when UPI app launch fails', (tester) async {
      final stay = _createTestStay(dueNowPaise: 650000);
      final acc = _createTestUpiAccount();
      final repo = MockGuestPayRepo(stay: stay, upiAccounts: [acc]);

      await tester.pumpWidget(_wrapGuestPayRentScreen(
        repo: repo,
        onLaunchUpi: (uri) async => false,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay with UPI app'));
      await tester.pumpAndSettle();

      expect(
        find.text('No UPI app found. Copy the UPI ID and pay from any UPI app.'),
        findsOneWidget,
      );
    });

    testWidgets('G1 Rent sheet Pay button opens G2 Pay rent screen',
        (tester) async {
      final stay = _createTestStay(dueNowPaise: 650000);
      final repo = MockGuestPayRepo(
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
          GoRoute(
            path: '/guest/pay/:stayId',
            builder: (context, state) => Scaffold(
              body: Text('G2 Pay rent for ${state.pathParameters['stayId']} amount ${state.extra}'),
            ),
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

      expect(find.text('Pay ₹6,500'), findsOneWidget);
      await tester.tap(find.text('Pay ₹6,500'));
      await tester.pumpAndSettle();

      expect(find.text('G2 Pay rent for stay-1 amount 650000'), findsOneWidget);
    });
  });
}
