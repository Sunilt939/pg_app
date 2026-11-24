import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/status_chip.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_payment_detail_screen.dart';
import 'package:app/features/owner/presentation/widgets/confirm_payment_sheet.dart';
import 'package:app/features/owner/presentation/widgets/reject_payment_sheet.dart';
import 'package:app/features/owner/presentation/widgets/reverse_payment_sheet.dart';

class MockOwnerRepo implements OwnerRepository {
  PaymentFeedItem? paymentItem;
  final List<PaymentAccount> accounts;
  String? signedUrl;
  bool shouldThrow = false;

  String? confirmedPaymentId;
  String? confirmedAccountId;
  String? rejectedPaymentId;
  String? rejectedReason;
  String? reversedPaymentId;
  String? reversedReason;

  MockOwnerRepo({
    this.paymentItem,
    this.accounts = const [],
    this.signedUrl,
    this.shouldThrow = false,
  });

  @override
  Future<PaymentFeedItem?> getPaymentDetail(String paymentId) async {
    if (shouldThrow) throw Exception('Network error');
    return paymentItem;
  }

  @override
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async => accounts;

  @override
  Future<String?> getSignedFileUrl(String fileId) async => signedUrl;

  @override
  Future<void> confirmPayment({
    required String paymentId,
    String? accountId,
  }) async {
    confirmedPaymentId = paymentId;
    confirmedAccountId = accountId;
    if (paymentItem != null) {
      paymentItem = PaymentFeedItem(
        paymentId: paymentItem!.paymentId,
        stayId: paymentItem!.stayId,
        pgId: paymentItem!.pgId,
        personId: paymentItem!.personId,
        fullName: paymentItem!.fullName,
        phone: paymentItem!.phone,
        roomNumber: paymentItem!.roomNumber,
        bedLabel: paymentItem!.bedLabel,
        amountPaise: paymentItem!.amountPaise,
        paidOn: paymentItem!.paidOn,
        status: 'confirmed',
        statusReason: paymentItem!.statusReason,
        note: paymentItem!.note,
        methodCode: paymentItem!.methodCode,
        methodLabel: paymentItem!.methodLabel,
        accountNickname: paymentItem!.accountNickname,
        receivedAccountId: accountId ?? paymentItem!.receivedAccountId,
        payerAppCode: paymentItem!.payerAppCode,
        payerAppLabel: paymentItem!.payerAppLabel,
        payerPhone: paymentItem!.payerPhone,
        utr: paymentItem!.utr,
        screenshotFileId: paymentItem!.screenshotFileId,
        reportedByGuest: paymentItem!.reportedByGuest,
        createdAt: paymentItem!.createdAt,
        confirmedAt: '2026-11-24T12:00:00Z',
      );
    }
  }

  @override
  Future<void> rejectPayment({
    required String paymentId,
    required String reason,
  }) async {
    rejectedPaymentId = paymentId;
    rejectedReason = reason;
    if (paymentItem != null) {
      paymentItem = PaymentFeedItem(
        paymentId: paymentItem!.paymentId,
        stayId: paymentItem!.stayId,
        pgId: paymentItem!.pgId,
        personId: paymentItem!.personId,
        fullName: paymentItem!.fullName,
        phone: paymentItem!.phone,
        roomNumber: paymentItem!.roomNumber,
        bedLabel: paymentItem!.bedLabel,
        amountPaise: paymentItem!.amountPaise,
        paidOn: paymentItem!.paidOn,
        status: 'rejected',
        statusReason: reason,
        note: paymentItem!.note,
        methodCode: paymentItem!.methodCode,
        methodLabel: paymentItem!.methodLabel,
        accountNickname: paymentItem!.accountNickname,
        receivedAccountId: paymentItem!.receivedAccountId,
        payerAppCode: paymentItem!.payerAppCode,
        payerAppLabel: paymentItem!.payerAppLabel,
        payerPhone: paymentItem!.payerPhone,
        utr: paymentItem!.utr,
        screenshotFileId: paymentItem!.screenshotFileId,
        reportedByGuest: paymentItem!.reportedByGuest,
        createdAt: paymentItem!.createdAt,
      );
    }
  }

  @override
  Future<void> reversePayment({
    required String paymentId,
    required String reason,
  }) async {
    reversedPaymentId = paymentId;
    reversedReason = reason;
    if (paymentItem != null) {
      paymentItem = PaymentFeedItem(
        paymentId: paymentItem!.paymentId,
        stayId: paymentItem!.stayId,
        pgId: paymentItem!.pgId,
        personId: paymentItem!.personId,
        fullName: paymentItem!.fullName,
        phone: paymentItem!.phone,
        roomNumber: paymentItem!.roomNumber,
        bedLabel: paymentItem!.bedLabel,
        amountPaise: paymentItem!.amountPaise,
        paidOn: paymentItem!.paidOn,
        status: 'reversed',
        statusReason: reason,
        note: paymentItem!.note,
        methodCode: paymentItem!.methodCode,
        methodLabel: paymentItem!.methodLabel,
        accountNickname: paymentItem!.accountNickname,
        receivedAccountId: paymentItem!.receivedAccountId,
        payerAppCode: paymentItem!.payerAppCode,
        payerAppLabel: paymentItem!.payerAppLabel,
        payerPhone: paymentItem!.payerPhone,
        utr: paymentItem!.utr,
        screenshotFileId: paymentItem!.screenshotFileId,
        reportedByGuest: paymentItem!.reportedByGuest,
        createdAt: paymentItem!.createdAt,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapScreen({
  required MockOwnerRepo repo,
  String paymentId = 'pay-1',
  String role = 'owner',
  GoRouter? router,
}) {
  final testRouter = router ??
      GoRouter(
        initialLocation: '/owner/payments/$paymentId',
        routes: [
          GoRoute(
            path: '/owner/payments/:paymentId',
            builder: (context, state) => OwnerPaymentDetailScreen(
              paymentId: state.pathParameters['paymentId'] ?? paymentId,
            ),
          ),
          GoRoute(
            path: '/owner/guests/:stayId',
            builder: (context, state) => Scaffold(
              body: Text('Guest detail for ${state.pathParameters['stayId']}'),
            ),
          ),
          GoRoute(
            path: '/receipt/:paymentId',
            builder: (context, state) => Scaffold(
              body: Text('Receipt for ${state.pathParameters['paymentId']}'),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(repo),
      activePgProvider.overrideWithValue(
        AuthPg(pgId: 'pg-1', name: 'Grand PG', role: role),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: testRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

const _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  const samplePendingPayment = PaymentFeedItem(
    paymentId: 'pay-1',
    stayId: 'stay-101',
    pgId: 'pg-1',
    fullName: 'Rahul Sharma',
    phone: '+919876543210',
    roomNumber: '101',
    bedLabel: 'A',
    amountPaise: 850000,
    paidOn: '2026-11-20',
    status: 'pending',
    methodCode: 'upi',
    methodLabel: 'UPI',
    accountNickname: 'HDFC Current',
    receivedAccountId: 'acc-1',
    payerAppCode: 'gpay',
    payerAppLabel: 'Google Pay',
    payerPhone: '+919876543210',
    utr: 'UTR123456789012',
    note: 'Rent for November',
    reportedByGuest: true,
    createdAt: '2026-11-20T10:30:00Z',
  );

  final sampleAccounts = [
    const PaymentAccount(
      id: 'acc-1',
      pgId: 'pg-1',
      nickname: 'HDFC Current',
      kind: 'bank',
      bankName: 'HDFC Bank',
      accountLast4: '4321',
      isDefault: true,
    ),
    const PaymentAccount(
      id: 'acc-2',
      pgId: 'pg-1',
      nickname: 'ICICI UPI',
      kind: 'upi',
      upiVpa: 'pg@icici',
    ),
  ];

  testWidgets('Pending payment renders all summary and details fields',
      (tester) async {
    final repo = MockOwnerRepo(
      paymentItem: samplePendingPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Summary sheet: amount and pending status chip
    expect(find.text('₹8,500'), findsOneWidget);
    expect(find.byType(StatusChip), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // Details sheet rows
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Room 101, bed A'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('20 Nov 2026'), findsOneWidget);
    expect(find.text('HDFC Current'), findsOneWidget);
    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('UTR123456789012'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.textContaining('by the guest'), findsOneWidget);
    expect(find.text('Rent for November'), findsOneWidget);

    // Sticky actions: Reject and Mark as received
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Mark as received'), findsOneWidget);
  });

  testWidgets('Tapping guest row navigates to guest detail (O6)',
      (tester) async {
    final repo = MockOwnerRepo(
      paymentItem: samplePendingPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rahul Sharma'));
    await tester.pumpAndSettle();

    expect(find.text('Guest detail for stay-101'), findsOneWidget);
  });

  testWidgets('Long pressing UTR copies to clipboard and shows snackbar',
      (tester) async {
    final repo = MockOwnerRepo(
      paymentItem: samplePendingPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('UTR123456789012'));
    await tester.pump();

    expect(find.text('Copied.'), findsOneWidget);
  });

  testWidgets('Mark as received flow confirms payment and opens receipt',
      (tester) async {
    final repo = MockOwnerRepo(
      paymentItem: samplePendingPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Tap primary "Mark as received"
    await tester.tap(find.text('Mark as received'));
    await tester.pumpAndSettle();

    // ConfirmPaymentSheet opens
    expect(find.byType(ConfirmPaymentSheet), findsOneWidget);
    expect(find.text('Mark as received'), findsWidgets);
    expect(find.textContaining('₹8,500 from Rahul Sharma'), findsOneWidget);

    // Tap confirm in sheet
    final confirmBtn = find.descendant(
      of: find.byType(ConfirmPaymentSheet),
      matching: find.byType(AppButton),
    );
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(repo.confirmedPaymentId, 'pay-1');
    expect(repo.confirmedAccountId, 'acc-1');

    // Navigates to receipt
    expect(find.text('Receipt for pay-1'), findsOneWidget);
  });

  testWidgets('Reject flow validates reason and rejects payment',
      (tester) async {
    final repo = MockOwnerRepo(
      paymentItem: samplePendingPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Tap secondary "Reject"
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    // RejectPaymentSheet opens
    expect(find.byType(RejectPaymentSheet), findsOneWidget);
    expect(find.text('Reject this payment?'), findsOneWidget);

    // Try submitting without reason -> shows validation error
    final rejectSubmitBtn = find.descendant(
      of: find.byType(RejectPaymentSheet),
      matching: find.byType(AppButton),
    );
    await tester.tap(rejectSubmitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Enter a reason.'), findsOneWidget);
    expect(repo.rejectedPaymentId, isNull);

    // Enter reason and submit
    await tester.enterText(find.byType(AppTextField), 'Wrong UTR number');
    await tester.pumpAndSettle();

    await tester.tap(rejectSubmitBtn);
    await tester.pumpAndSettle();

    expect(repo.rejectedPaymentId, 'pay-1');
    expect(repo.rejectedReason, 'Wrong UTR number');
    expect(find.text('Payment rejected.'), findsOneWidget);
  });

  testWidgets('Confirmed payment shows View receipt and Reverse button for owner',
      (tester) async {
    const confirmedPayment = PaymentFeedItem(
      paymentId: 'pay-2',
      stayId: 'stay-102',
      pgId: 'pg-1',
      fullName: 'Priya Singh',
      roomNumber: '102',
      amountPaise: 1200000,
      paidOn: '2026-11-21',
      status: 'confirmed',
      methodCode: 'bank',
      methodLabel: 'Bank transfer',
      confirmedAt: '2026-11-21T14:00:00Z',
    );

    final repo = MockOwnerRepo(
      paymentItem: confirmedPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo, paymentId: 'pay-2', role: 'owner'));
    await tester.pumpAndSettle();

    // Status chip confirmed
    expect(
      find.descendant(
        of: find.byType(StatusChip),
        matching: find.text('Confirmed'),
      ),
      findsOneWidget,
    );

    // View receipt sticky action
    expect(find.text('View receipt'), findsOneWidget);

    // Reverse payment button visible for owner
    expect(find.text('Reverse payment'), findsOneWidget);

    // Tapping View receipt navigates to receipt
    await tester.tap(find.text('View receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt for pay-2'), findsOneWidget);
  });

  testWidgets('Caretaker does NOT see Reverse payment button',
      (tester) async {
    const confirmedPayment = PaymentFeedItem(
      paymentId: 'pay-2',
      stayId: 'stay-102',
      pgId: 'pg-1',
      fullName: 'Priya Singh',
      roomNumber: '102',
      amountPaise: 1200000,
      paidOn: '2026-11-21',
      status: 'confirmed',
      methodCode: 'bank',
      methodLabel: 'Bank transfer',
      confirmedAt: '2026-11-21T14:00:00Z',
    );

    final repo = MockOwnerRepo(
      paymentItem: confirmedPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo, paymentId: 'pay-2', role: 'caretaker'));
    await tester.pumpAndSettle();

    expect(find.text('View receipt'), findsOneWidget);
    expect(find.text('Reverse payment'), findsNothing);
  });

  testWidgets('Reverse payment sheet validates reason and reverses payment',
      (tester) async {
    const confirmedPayment = PaymentFeedItem(
      paymentId: 'pay-2',
      stayId: 'stay-102',
      pgId: 'pg-1',
      fullName: 'Priya Singh',
      roomNumber: '102',
      amountPaise: 1200000,
      paidOn: '2026-11-21',
      status: 'confirmed',
      methodCode: 'bank',
      methodLabel: 'Bank transfer',
      confirmedAt: '2026-11-21T14:00:00Z',
    );

    final repo = MockOwnerRepo(
      paymentItem: confirmedPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo, paymentId: 'pay-2', role: 'manager'));
    await tester.pumpAndSettle();

    // Tap Reverse payment
    await tester.tap(find.text('Reverse payment'));
    await tester.pumpAndSettle();

    // ReversePaymentSheet opens
    expect(find.byType(ReversePaymentSheet), findsOneWidget);
    expect(find.text('Reverse this payment?'), findsOneWidget);

    final reverseSubmitBtn = find.descendant(
      of: find.byType(ReversePaymentSheet),
      matching: find.byType(AppButton),
    );

    // Try submitting without reason
    await tester.tap(reverseSubmitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Enter a reason.'), findsOneWidget);
    expect(repo.reversedPaymentId, isNull);

    // Enter reason and submit
    await tester.enterText(find.byType(AppTextField), 'Entered by mistake');
    await tester.pumpAndSettle();

    await tester.tap(reverseSubmitBtn);
    await tester.pumpAndSettle();

    expect(repo.reversedPaymentId, 'pay-2');
    expect(repo.reversedReason, 'Entered by mistake');
    expect(find.text('Payment reversed.'), findsOneWidget);
  });

  testWidgets('Rejected payment shows reason and has no sticky actions',
      (tester) async {
    const rejectedPayment = PaymentFeedItem(
      paymentId: 'pay-3',
      stayId: 'stay-103',
      pgId: 'pg-1',
      fullName: 'Vikram Mehta',
      amountPaise: 500000,
      paidOn: '2026-11-19',
      status: 'rejected',
      statusReason: 'Invalid screenshot',
      methodCode: 'cash',
      methodLabel: 'Cash',
    );

    final repo = MockOwnerRepo(
      paymentItem: rejectedPayment,
      accounts: sampleAccounts,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo, paymentId: 'pay-3'));
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Invalid screenshot'), findsOneWidget);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Mark as received'), findsNothing);
    expect(find.text('View receipt'), findsNothing);
    expect(find.text('Reverse payment'), findsNothing);
  });

  testWidgets('Error state shows retry button',
      (tester) async {
    final repo = MockOwnerRepo(shouldThrow: true);

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);

    // Fix error and retry
    repo.shouldThrow = false;
    repo.paymentItem = samplePendingPayment;

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('₹8,500'), findsOneWidget);
  });

  testWidgets(
      'Payment with screenshot renders thumbnail and opens full screen viewer',
      (tester) async {
    const paymentWithScreenshot = PaymentFeedItem(
      paymentId: 'pay-screenshot',
      stayId: 'stay-101',
      pgId: 'pg-1',
      fullName: 'Rahul Sharma',
      amountPaise: 850000,
      paidOn: '2026-11-20',
      status: 'pending',
      screenshotFileId: 'file-123',
    );

    final repo = MockOwnerRepo(
      paymentItem: paymentWithScreenshot,
      accounts: sampleAccounts,
      signedUrl: 'https://example.com/screenshot.jpg',
    );

    await tester.pumpWidget(
      _wrapScreen(repo: repo, paymentId: 'pay-screenshot'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screenshot'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Tap screenshot thumbnail
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();

    // Full screen viewer opened with close button
    expect(find.byIcon(AppIcons.close), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Tap close button pops full screen viewer
    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
