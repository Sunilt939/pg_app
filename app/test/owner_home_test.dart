import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/dates.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/progress_bar_thin.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_home_screen.dart';

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
}

class MockOwnerRepo implements OwnerRepository {
  final Map<String, OwnerHomeBundle> bundlesByMonth = {};
  OwnerHomeBundle? defaultBundle;
  bool shouldThrow = false;
  String? confirmedPaymentId;
  String? rejectedPaymentId;
  String? lastRequestedMonth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<OwnerHomeBundle> getOwnerHomeBundle({
    required String pgId,
    required String month,
  }) async {
    lastRequestedMonth = month;
    if (shouldThrow) throw Exception('Failed to load home bundle');
    return bundlesByMonth[month] ??
        defaultBundle ??
        OwnerHomeBundle(
          setupStatus: PgSetupStatus(pgId: pgId),
        );
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
  }
}

Widget _wrapScreen({
  required MockOwnerRepo repo,
  String initialLocation = '/owner/home',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/owner/home',
        builder: (context, state) => const OwnerHomeScreen(),
      ),
      GoRoute(
        path: '/owner/rooms/setup',
        builder: (context, state) => const Scaffold(body: Text('Rooms setup screen')),
      ),
      GoRoute(
        path: '/owner/accounts/new',
        builder: (context, state) => const Scaffold(body: Text('New account screen')),
      ),
      GoRoute(
        path: '/owner/guests/new',
        builder: (context, state) => const Scaffold(body: Text('Add guest screen')),
      ),
      GoRoute(
        path: '/owner/guests',
        builder: (context, state) => Scaffold(
          body: Text('Guests tab with query ${state.uri.queryParameters['tab']}'),
        ),
      ),
      GoRoute(
        path: '/owner/guests/:stayId',
        builder: (context, state) => Scaffold(
          body: Text('Guest detail for ${state.pathParameters['stayId']}'),
        ),
      ),
      GoRoute(
        path: '/owner/guests/:stayId/pay',
        builder: (context, state) => Scaffold(
          body: Text('Record pay for ${state.pathParameters['stayId']}'),
        ),
      ),
      GoRoute(
        path: '/owner/payments/:paymentId',
        builder: (context, state) => Scaffold(
          body: Text('Payment detail for ${state.pathParameters['paymentId']}'),
        ),
      ),
      GoRoute(
        path: '/owner/collections',
        builder: (context, state) => const Scaffold(body: Text('Collections screen')),
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
  final nowIst = DateFormat.toIst(DateTime.now());
  final currentMonthKey =
      '${nowIst.year}-${nowIst.month.toString().padLeft(2, '0')}-01';
  final currentMonthTitle =
      DateFormat.formatMonthYear(DateTime(nowIst.year, nowIst.month, 1));

  final prevMonthDate = DateTime(nowIst.year, nowIst.month - 1, 1);
  final prevMonthKey =
      '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}-01';
  final prevMonthTitle = DateFormat.formatMonthYear(prevMonthDate);

  testWidgets('O2: Brand-new PG displays Setup checklist and hides summary and needs attention', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(
        pgId: 'pg-1',
        roomsCount: 0,
        accountsCount: 0,
        guestsCount: 0,
      ),
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Set up your PG'), findsOneWidget);
    expect(find.text('Three quick steps and you can start collecting rent.'), findsOneWidget);
    expect(find.text('Add rooms and beds'), findsOneWidget);
    expect(find.text('Add a receiving account'), findsOneWidget);
    expect(find.text('Add your first guest'), findsOneWidget);

    // Summary sheet, buttons row, and Needs attention are hidden while guestsCount == 0
    expect(find.text('To collect this month'), findsNothing);
    expect(find.text('Needs attention'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Record payment'), findsNothing);

    // "Where was the money received?" is always present
    expect(find.text('Where was the money received?'), findsOneWidget);

    // Tap step 1 opens rooms setup
    await tester.tap(find.text('Add rooms and beds'));
    await tester.pumpAndSettle();
    expect(find.text('Rooms setup screen'), findsOneWidget);
  });

  testWidgets('O2: Active PG with guests renders Summary sheet, buttons, and Needs attention', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(
        pgId: 'pg-1',
        roomsCount: 10,
        accountsCount: 2,
        guestsCount: 5,
      ),
      overview: PgOverview(
        pgId: 'pg-1',
        overdueTotalPaise: 1200000,
        pendingPaymentCount: 1,
      ),
      monthlySummary: PgMonthlySummary(
        pgId: 'pg-1',
        periodMonth: '2026-11-01',
        expectedPaise: 16050000,
        collectedPaise: 11200000,
        pendingPaise: 4850000,
      ),
      pendingPayments: [
        PaymentFeedItem(
          paymentId: 'pay-pending-1',
          stayId: 'stay-1',
          fullName: 'Aarav Patel',
          roomNumber: '101',
          amountPaise: 250000,
          paidOn: '2026-11-03',
          status: 'pending',
          methodCode: 'upi',
          methodLabel: 'UPI',
        ),
      ],
      overdueGuests: [
        GuestListItem(
          stayId: 'stay-2',
          pgId: 'pg-1',
          pgName: 'Sunrise PG',
          personId: 'person-2',
          fullName: 'Rahul Sharma',
          phone: '+919876543211',
          stayStatus: 'active',
          joinDate: '2026-06-01',
          monthlyRentPaise: 1000000,
          billingDay: 1,
          roomNumber: '102',
          bedLabel: 'A',
          hasSignedIn: true,
          overduePaise: 650000,
          oldestUnpaidDueDate: '2026-10-27',
          attentionState: 'overdue',
        ),
      ],
      openGuests: [
        GuestListItem(
          stayId: 'stay-1',
          pgId: 'pg-1',
          pgName: 'Sunrise PG',
          personId: 'person-1',
          fullName: 'Aarav Patel',
          phone: '+919876543210',
          stayStatus: 'active',
          joinDate: '2026-06-01',
          monthlyRentPaise: 1000000,
          billingDay: 1,
          roomNumber: '101',
          bedLabel: 'A',
          hasSignedIn: true,
          attentionState: 'paid',
        ),
      ],
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Setup card is gone
    expect(find.text('Set up your PG'), findsNothing);

    // Summary sheet content
    expect(find.text(currentMonthTitle), findsOneWidget);
    expect(find.text('To collect this month'), findsOneWidget);
    expect(find.text('₹48,500'), findsOneWidget);
    expect(find.byType(ProgressBarThin), findsOneWidget);
    expect(find.text('₹1,12,000 of ₹1,60,500 collected'), findsOneWidget);

    // Overdue row & overdue chip in needs attention
    expect(find.text('Overdue'), findsNWidgets(2));
    expect(find.text('₹12,000'), findsOneWidget);

    // Action buttons (main button + inline action on overdue row)
    expect(find.widgetWithText(AppButton, 'Record payment'), findsNWidgets(2));
    expect(find.widgetWithText(AppButton, 'Add guest'), findsOneWidget);

    // Needs attention header with count 2 (1 pending + 1 overdue)
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Pending payment row
    expect(find.text('Aarav Patel'), findsOneWidget);
    expect(find.text('Reported ₹2,500 by UPI, 3 Nov 2026'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Reject'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Confirm'), findsOneWidget);

    // Overdue guest row
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Overdue since 27 Oct'), findsOneWidget);
    expect(find.text('₹6,500'), findsOneWidget);

    // Money received row
    await tester.scrollUntilVisible(
      find.text('Where was the money received?'),
      200,
    );
    expect(find.text('Where was the money received?'), findsOneWidget);
  });

  testWidgets('O2: Month navigation switches month and loads data', (tester) async {
    final repo = MockOwnerRepo();
    repo.bundlesByMonth[currentMonthKey] = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
      monthlySummary: PgMonthlySummary(
        pgId: 'pg-1',
        periodMonth: 'current',
        expectedPaise: 1000000,
        collectedPaise: 800000,
        pendingPaise: 200000,
      ),
    );
    repo.bundlesByMonth[prevMonthKey] = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
      monthlySummary: PgMonthlySummary(
        pgId: 'pg-1',
        periodMonth: 'prev',
        expectedPaise: 900000,
        collectedPaise: 900000,
        pendingPaise: 0,
      ),
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);
    expect(find.text('₹2,000'), findsOneWidget);

    // Tap left chevron
    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text(prevMonthTitle), findsOneWidget);
    expect(find.text('To collect in $prevMonthTitle'), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);
  });

  testWidgets('O2: Record payment button opens guest picker option sheet and navigates to O7', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
      openGuests: [
        GuestListItem(
          stayId: 'stay-pick-1',
          pgId: 'pg-1',
          pgName: 'Sunrise PG',
          personId: 'p-1',
          fullName: 'Kiran Kumar',
          phone: '+919876543210',
          stayStatus: 'active',
          joinDate: '2026-01-01',
          monthlyRentPaise: 800000,
          billingDay: 1,
          roomNumber: '101',
          bedLabel: 'A',
          hasSignedIn: true,
          attentionState: 'paid',
        ),
      ],
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    // Tap Record payment button
    await tester.tap(find.widgetWithText(AppButton, 'Record payment'));
    await tester.pumpAndSettle();

    // OptionSheet opens
    expect(find.text('Who paid?'), findsOneWidget);
    expect(find.text('Kiran Kumar'), findsOneWidget);
    expect(find.text('Room 101'), findsOneWidget);

    // Tap guest in sheet
    await tester.tap(find.text('Kiran Kumar'));
    await tester.pumpAndSettle();

    expect(find.text('Record pay for stay-pick-1'), findsOneWidget);
  });

  testWidgets('O2: Needs attention empty state shows check icon and up to date message', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
      pendingPayments: [],
      overdueGuests: [],
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Nothing needs attention'), findsOneWidget);
    expect(find.text('Everyone is up to date.'), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('O2: Tapping overdue row navigates to Guests tab with overdue filter', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
      overview: PgOverview(pgId: 'pg-1', overdueTotalPaise: 500000),
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();

    expect(find.text('Guests tab with query overdue'), findsOneWidget);
  });

  testWidgets('O2: Tapping Where was the money received row navigates to Collections screen', (tester) async {
    final repo = MockOwnerRepo();
    repo.defaultBundle = const OwnerHomeBundle(
      setupStatus: PgSetupStatus(pgId: 'pg-1', roomsCount: 1, accountsCount: 1, guestsCount: 1),
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Where was the money received?'));
    await tester.pumpAndSettle();

    expect(find.text('Collections screen'), findsOneWidget);
  });
}
