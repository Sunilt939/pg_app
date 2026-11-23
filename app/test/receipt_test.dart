import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/tick_badge.dart';
import 'package:app/features/shared/domain/receipt_detail.dart';
import 'package:app/features/shared/domain/receipt_repository.dart';
import 'package:app/features/shared/presentation/providers/receipt_provider.dart';
import 'package:app/features/shared/presentation/screens/receipt_screen.dart';

class MockReceiptRepo implements ReceiptRepository {
  final ReceiptDetail? receipt;

  MockReceiptRepo({this.receipt});

  @override
  Future<ReceiptDetail?> getReceiptDetail(String paymentId) async => receipt;
}

Widget _wrapReceiptScreen({
  required MockReceiptRepo repo,
  String paymentId = 'pay-1',
  bool isNew = false,
}) {
  final router = GoRouter(
    initialLocation: '/receipt/$paymentId',
    routes: [
      GoRoute(
        path: '/receipt/:paymentId',
        builder: (context, state) => ReceiptScreen(
          paymentId: state.pathParameters['paymentId'] ?? paymentId,
          isNew: isNew,
        ),
      ),
      GoRoute(
        path: '/owner/guests/:stayId',
        builder: (context, state) => Scaffold(
          body: Text('Guest detail for ${state.pathParameters['stayId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      receiptRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

ReceiptDetail _createTestReceipt({
  String status = 'confirmed',
  String? statusReason,
  int amountPaise = 700000,
  int unallocatedPaise = 50000,
}) {
  return ReceiptDetail(
    receiptId: 'rc-1',
    receiptNo: 123,
    issuedAt: DateTime(2026, 11, 12),
    paymentId: 'pay-1',
    stayId: 'stay-1',
    pgId: 'pg-1',
    pgName: 'Green Meadows PG',
    pgContactPhone: '+919876543210',
    pgAddressLine1: '12th Cross, Indiranagar',
    pgArea: 'Indiranagar',
    pgCity: 'Bengaluru',
    guestName: 'Kiran Kumar',
    guestPhone: '+919876543211',
    roomNumber: '101',
    bedLabel: 'A',
    amountPaise: amountPaise,
    paidOn: DateTime(2026, 11, 12),
    status: status,
    statusReason: statusReason,
    methodCode: 'upi',
    methodLabel: 'UPI',
    payerAppLabel: 'PhonePe',
    utr: 'UTR99887766',
    allocations: const [
      ReceiptAllocation(
        description: 'Rent for Nov 2026',
        amountPaise: 650000,
      ),
    ],
    unallocatedPaise: unallocatedPaise,
  );
}

void main() {
  testWidgets('S1 renders receipt paper with all details, stamp and footer',
      (tester) async {
    final repo = MockReceiptRepo(receipt: _createTestReceipt());
    await tester.pumpWidget(_wrapReceiptScreen(repo: repo, isNew: false));
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Green Meadows PG'), findsOneWidget);
    expect(find.text('No. 000123'), findsOneWidget);
    expect(find.text('12th Cross, Indiranagar, Indiranagar, Bengaluru'), findsOneWidget);

    expect(find.text('Amount received'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('UPI, PhonePe'), findsOneWidget);
    expect(find.text('12 Nov 2026'), findsWidgets);

    expect(find.text('From'), findsOneWidget);
    expect(find.text('Kiran Kumar'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Room 101, bed A'), findsOneWidget);
    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('UTR99887766'), findsOneWidget);

    expect(find.text('Paid towards'), findsOneWidget);
    expect(find.text('Rent for Nov 2026'), findsOneWidget);
    expect(find.text('Advance credit'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    expect(find.text('Issued through PG App'), findsOneWidget);
    expect(find.text('Share receipt'), findsOneWidget);
    // Not new: no tick badge, no done button
    expect(find.byType(TickBadge), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('S1 arrival block shown when isNew is true and Done navigates back',
      (tester) async {
    final repo = MockReceiptRepo(receipt: _createTestReceipt());
    await tester.pumpWidget(_wrapReceiptScreen(repo: repo, isNew: true));
    await tester.pumpAndSettle();

    expect(find.byType(TickBadge), findsOneWidget);
    expect(find.text('Payment recorded'), findsOneWidget);
    final doneBtn = find.widgetWithText(AppButton, 'Done');
    expect(doneBtn, findsOneWidget);

    await tester.scrollUntilVisible(doneBtn, 200);
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    expect(find.text('Guest detail for stay-1'), findsOneWidget);
  });

  testWidgets('S1 renders reversed stamp and reason when status is reversed',
      (tester) async {
    final repo = MockReceiptRepo(
      receipt: _createTestReceipt(
        status: 'reversed',
        statusReason: 'Cheque bounced',
      ),
    );
    await tester.pumpWidget(_wrapReceiptScreen(repo: repo, isNew: false));
    await tester.pumpAndSettle();

    expect(find.text('Reversed'), findsOneWidget);
    expect(find.text('Reversed: Cheque bounced'), findsOneWidget);
  });

  testWidgets('S1 shows unavailable state when receipt is null',
      (tester) async {
    final repo = MockReceiptRepo(receipt: null);
    await tester.pumpWidget(_wrapReceiptScreen(repo: repo, isNew: false));
    await tester.pumpAndSettle();

    expect(find.text("This receipt isn't available"), findsOneWidget);
    expect(find.text('It may not be confirmed yet, or you may not have access to it.'), findsOneWidget);
  });
}
