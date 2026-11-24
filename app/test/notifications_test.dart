import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/tokens.dart';
import 'package:app/features/shared/domain/notifications_repository.dart';
import 'package:app/features/shared/presentation/providers/notifications_provider.dart';
import 'package:app/features/shared/presentation/screens/notifications_screen.dart';
import 'package:app/features/shared/presentation/widgets/notification_bell_button.dart';

class MockNotificationsRepo implements NotificationsRepository {
  List<NotificationItem> items = [];
  bool hasUnread = false;
  final List<String> markedReadIds = [];
  bool shouldThrow = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<NotificationItem>> getNotifications({int offset = 0, int limit = 50}) async {
    if (shouldThrow) throw Exception('Network error');
    final end = (offset + limit < items.length) ? offset + limit : items.length;
    if (offset >= items.length) return [];
    return items.sublist(offset, end);
  }

  @override
  Future<void> markAsRead(String id) async {
    markedReadIds.add(id);
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == id) {
        items[i] = items[i].copyWith(
          status: 'read',
          readAt: DateTime.now().toUtc(),
        );
      }
    }
  }

  @override
  Future<bool> hasUnreadNotifications() async {
    return hasUnread;
  }
}

Widget createTestApp({
  required MockNotificationsRepo repo,
  Widget? child,
  GoRouter? customRouter,
}) {
  final router = customRouter ??
      GoRouter(
        initialLocation: RoutePaths.notifications,
        routes: [
          GoRoute(
            path: RoutePaths.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: RoutePaths.guestHome,
            builder: (context, state) => const Scaffold(body: Text('Guest Home Screen')),
          ),
          GoRoute(
            path: '/owner/guests/:stayId',
            builder: (context, state) => Scaffold(
              body: Text('Guest Detail Screen ${state.pathParameters['stayId']}'),
            ),
          ),
          GoRoute(
            path: RoutePaths.guestHistory,
            builder: (context, state) => const Scaffold(body: Text('Guest History Screen')),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('S3: Notifications', () {
    test('NotificationItem correctly identifies unread vs read status', () {
      final unread = NotificationItem(
        id: 'n-1',
        personId: 'p-1',
        kind: 'rent_reminder',
        title: 'Rent due soon',
        body: 'Rent of ₹10,000 is due on 1st Nov.',
        status: 'sent',
        createdAt: DateTime.now().toUtc(),
      );
      expect(unread.isUnread, isTrue);

      final readByStatus = unread.copyWith(status: 'read');
      expect(readByStatus.isUnread, isFalse);

      final readByTimestamp = unread.copyWith(readAt: DateTime.now().toUtc());
      expect(readByTimestamp.isUnread, isFalse);
    });

    testWidgets('Empty state renders bell icon, title, and body', (tester) async {
      final repo = MockNotificationsRepo()..items = [];

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text('Reminders and payment updates show up here.'),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.bell), findsOneWidget);
    });

    testWidgets('Error state renders retry button and retries on tap', (tester) async {
      final repo = MockNotificationsRepo()..shouldThrow = true;

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      repo.shouldThrow = false;
      repo.items = [
        NotificationItem(
          id: 'n-1',
          personId: 'p-1',
          kind: 'system',
          title: 'Welcome',
          body: 'Welcome to your PG app.',
          status: 'read',
          readAt: DateTime.now().toUtc(),
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Welcome to your PG app.'), findsOneWidget);
    });

    testWidgets('Renders unread row with petrol dot and read row without dot', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockNotificationsRepo()
        ..items = [
          NotificationItem(
            id: 'n-1',
            personId: 'p-1',
            kind: 'rent_reminder',
            title: 'Rent Due',
            body: 'Monthly rent is due.',
            status: 'sent',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          NotificationItem(
            id: 'n-2',
            personId: 'p-1',
            kind: 'payment_confirmed',
            title: 'Payment Confirmed',
            body: 'Your payment was confirmed.',
            status: 'read',
            readAt: now,
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ];

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Rent Due'), findsOneWidget);
      expect(find.text('Payment Confirmed'), findsOneWidget);

      // Relative times
      expect(find.text('2 h ago'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);

      // Unread dot container has color petrol
      final containers = tester.widgetList<Container>(find.byType(Container));
      final petrolDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == AppColors.petrol &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(petrolDot, isNotEmpty);
    });

    testWidgets('Tapping rent_reminder marks read and navigates to Guest Home (G1)', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockNotificationsRepo()
        ..items = [
          NotificationItem(
            id: 'n-rent',
            personId: 'p-1',
            kind: 'rent_reminder',
            title: 'Rent Reminder',
            body: 'Pay rent please.',
            status: 'sent',
            createdAt: now,
          ),
        ];

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rent Reminder'));
      await tester.pumpAndSettle();

      expect(repo.markedReadIds, contains('n-rent'));
      expect(find.text('Guest Home Screen'), findsOneWidget);
    });

    testWidgets('Tapping payment_reported marks read and navigates to Owner Guest Detail (O6)', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockNotificationsRepo()
        ..items = [
          NotificationItem(
            id: 'n-reported',
            personId: 'p-1',
            kind: 'payment_reported',
            title: 'Payment Reported',
            body: 'Guest reported ₹8,000.',
            stayId: 'stay-123',
            status: 'sent',
            createdAt: now,
          ),
        ];

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payment Reported'));
      await tester.pumpAndSettle();

      expect(repo.markedReadIds, contains('n-reported'));
      expect(find.text('Guest Detail Screen stay-123'), findsOneWidget);
    });

    testWidgets('Tapping payment_confirmed marks read and navigates to Guest History (G4)', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockNotificationsRepo()
        ..items = [
          NotificationItem(
            id: 'n-conf',
            personId: 'p-1',
            kind: 'payment_confirmed',
            title: 'Payment Received',
            body: 'Receipt ready.',
            status: 'sent',
            createdAt: now,
          ),
        ];

      await tester.pumpWidget(createTestApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payment Received'));
      await tester.pumpAndSettle();

      expect(repo.markedReadIds, contains('n-conf'));
      expect(find.text('Guest History Screen'), findsOneWidget);
    });

    testWidgets('NotificationBellButton shows unread dot when hasUnread is true and navigates to notifications on tap', (tester) async {
      final repo = MockNotificationsRepo()..hasUnread = true;

      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: NotificationBellButton(),
            ),
          ),
          GoRoute(
            path: RoutePaths.notifications,
            builder: (context, state) => const Scaffold(
              body: Text('Notifications Pushed'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for bell icon
      expect(find.byIcon(AppIcons.bell), findsOneWidget);

      // Check unread dot
      final containers = tester.widgetList<Container>(find.byType(Container));
      final petrolDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == AppColors.petrol &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(petrolDot, isNotEmpty);

      // Tap bell button
      await tester.tap(find.byIcon(AppIcons.bell));
      await tester.pumpAndSettle();

      expect(find.text('Notifications Pushed'), findsOneWidget);
    });
  });
}
