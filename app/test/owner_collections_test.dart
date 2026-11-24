import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/format/dates.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/room_tile.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_collections_screen.dart';

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
  final Map<String, MonthCollections> collectionsByMonth = {};
  bool shouldThrow = false;
  String? lastRequestedMonth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<MonthCollections> getMonthCollections({
    required String pgId,
    required String month,
  }) async {
    lastRequestedMonth = month;
    if (shouldThrow) throw Exception('Failed to load collections');
    return collectionsByMonth[month] ?? MonthCollections.empty(pgId, month);
  }
}

Widget _wrapScreen({
  required MockOwnerRepo repo,
  String initialLocation = '/owner/collections',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/owner/collections',
        builder: (context, state) => const OwnerCollectionsScreen(),
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
  final currentMonthTitle = DateFormat.formatMonthYear(DateTime(nowIst.year, nowIst.month, 1));

  final prevMonthDate = DateTime(nowIst.year, nowIst.month - 1, 1);
  final prevMonthKey =
      '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}-01';
  final prevMonthTitle = DateFormat.formatMonthYear(prevMonthDate);

  testWidgets('O10: Renders Top bar with back and title Money received', (tester) async {
    final repo = MockOwnerRepo();

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Money received'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsOneWidget);
  });

  testWidgets('O10: Total sheet renders current month name, next arrow disabled, and total', (tester) async {
    final repo = MockOwnerRepo();
    repo.collectionsByMonth[currentMonthKey] = MonthCollections(
      pgId: 'pg-1',
      month: currentMonthKey,
      totalPaise: 4500000,
      paymentCount: 5,
      byAccount: const [
        AccountCollection(
          accountId: 'acc-1',
          accountNickname: 'HDFC Current',
          methodCode: 'bank',
          methodLabel: 'Bank transfer',
          paymentCount: 3,
          totalPaise: 3000000,
        ),
        AccountCollection(
          accountId: 'acc-2',
          accountNickname: 'Google Pay UPI',
          methodCode: 'upi',
          methodLabel: 'UPI',
          paymentCount: 2,
          totalPaise: 1500000,
        ),
      ],
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);
    expect(find.text('Received in $currentMonthTitle'), findsOneWidget);
    expect(find.text('₹45,000'), findsOneWidget);
    expect(find.text('5 payments'), findsOneWidget);

    // Accounts list
    expect(find.text('HDFC Current'), findsOneWidget);
    expect(find.text('3 payments'), findsOneWidget);
    expect(find.text('₹30,000'), findsOneWidget);

    expect(find.text('Google Pay UPI'), findsOneWidget);
    expect(find.text('2 payments'), findsOneWidget);
    expect(find.text('₹15,000'), findsOneWidget);

    expect(find.byType(RoomTile), findsNWidgets(2));
  });

  testWidgets('O10: Left chevron navigates to previous month and right chevron navigates back', (tester) async {
    final repo = MockOwnerRepo();
    repo.collectionsByMonth[currentMonthKey] = MonthCollections(
      pgId: 'pg-1',
      month: currentMonthKey,
      totalPaise: 5000000,
      paymentCount: 5,
    );
    repo.collectionsByMonth[prevMonthKey] = MonthCollections(
      pgId: 'pg-1',
      month: prevMonthKey,
      totalPaise: 3500000,
      paymentCount: 4,
    );

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);

    // Tap left chevron to go to previous month
    await tester.tap(find.byIcon(AppIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text(prevMonthTitle), findsOneWidget);
    expect(find.text('Received in $prevMonthTitle'), findsOneWidget);
    expect(find.text('₹35,000'), findsOneWidget);
    expect(find.text('4 payments'), findsOneWidget);
    expect(repo.lastRequestedMonth, prevMonthKey);

    // Tap right chevron to return to current month
    await tester.tap(find.byIcon(AppIcons.chevronRight));
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);
    expect(find.text('₹50,000'), findsOneWidget);
    expect(repo.lastRequestedMonth, currentMonthKey);
  });

  testWidgets('O10: Empty month shows Money(0), Nothing received this month, and EmptyState', (tester) async {
    final repo = MockOwnerRepo();
    // No data in collectionsByMonth for currentMonthKey

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);
    expect(find.text('Nothing received this month.'), findsOneWidget);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nothing received'), findsOneWidget);
    expect(find.text('Money you record or confirm for this month will be listed by account.'), findsOneWidget);
  });

  testWidgets('O10: Error state renders retry button and recovers on retry', (tester) async {
    final repo = MockOwnerRepo();
    repo.shouldThrow = true;

    await tester.pumpWidget(_wrapScreen(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);

    repo.shouldThrow = false;
    repo.collectionsByMonth[currentMonthKey] = MonthCollections(
      pgId: 'pg-1',
      month: currentMonthKey,
      totalPaise: 1000000,
      paymentCount: 1,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('₹10,000'), findsOneWidget);
  });
}
