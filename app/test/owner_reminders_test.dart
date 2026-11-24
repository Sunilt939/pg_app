import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_reminders_screen.dart';

class MockOwnerRepo implements OwnerRepository {
  List<ReminderRule> rules = [];
  bool shouldThrow = false;
  bool shouldThrowDuplicate = false;
  final List<String> deletedIds = [];
  final List<Map<String, dynamic>> savedRules = [];
  final Map<String, bool> toggledRules = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ReminderRule>> getReminderRules(String pgId) async {
    if (shouldThrow) throw Exception('Network error');
    return rules;
  }

  @override
  Future<void> saveReminderRule({
    String? id,
    required String pgId,
    required int daysFromDue,
    required String channel,
  }) async {
    if (shouldThrowDuplicate) {
      throw const DuplicateReminderRuleException();
    }
    savedRules.add({
      'id': id,
      'pgId': pgId,
      'daysFromDue': daysFromDue,
      'channel': channel,
    });
    if (id == null) {
      rules.add(
        ReminderRule(
          id: 'rule-${rules.length + 1}',
          pgId: pgId,
          daysFromDue: daysFromDue,
          channel: channel,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } else {
      final index = rules.indexWhere((r) => r.id == id);
      if (index != -1) {
        rules[index] = rules[index].copyWith(
          daysFromDue: daysFromDue,
          channel: channel,
        );
      }
    }
  }

  @override
  Future<void> toggleReminderRule({
    required String id,
    required bool isActive,
  }) async {
    toggledRules[id] = isActive;
    final index = rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      rules[index] = rules[index].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deleteReminderRule(String id) async {
    deletedIds.add(id);
    rules.removeWhere((r) => r.id == id);
  }
}

class MockAuthRepo implements AuthRepository {
  final AuthContext myContext;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MockAuthRepo({
    this.myContext = const AuthContext(
      person: AuthPerson(id: 'person-1', phone: '+919999999999', fullName: 'Owner Test'),
      pgs: [AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner')],
      stays: [],
    ),
  });

  @override
  Future<AuthContext> getMyContext() async => myContext;

  @override
  Future<String?> getSelectedPgId() async => 'pg-1';
}

Widget createTestApp({
  required MockOwnerRepo ownerRepo,
  MockAuthRepo? authRepo,
}) {
  final effectiveAuthRepo = authRepo ?? MockAuthRepo();

  final router = GoRouter(
    initialLocation: RoutePaths.ownerReminders,
    routes: [
      GoRoute(
        path: RoutePaths.ownerReminders,
        builder: (context, state) => const OwnerRemindersScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(effectiveAuthRepo),
      ownerRepositoryProvider.overrideWithValue(ownerRepo),
      activePgProvider.overrideWithValue(
        const AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
      ),
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

  group('O15: Reminders', () {
    test('ReminderRule model serialization and copyWith', () {
      final now = DateTime.now().toUtc();
      final rule = ReminderRule(
        id: 'r-1',
        pgId: 'pg-1',
        daysFromDue: -3,
        channel: 'push',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = rule.toJson();
      expect(json['days_from_due'], -3);
      expect(json['channel'], 'push');

      final fromJson = ReminderRule.fromJson(json);
      expect(fromJson.daysFromDue, -3);

      final updated = rule.copyWith(isActive: false, daysFromDue: 0);
      expect(updated.isActive, isFalse);
      expect(updated.daysFromDue, 0);
    });

    testWidgets('Empty state renders notice banner, bell icon, title, and Add button', (tester) async {
      final repo = MockOwnerRepo()..rules = [];

      await tester.pumpWidget(createTestApp(ownerRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
      expect(
        find.text('Reminders will start sending soon. You can set the timing now.'),
        findsOneWidget,
      );
      expect(find.text('No reminders'), findsOneWidget);
      expect(
        find.text('Add reminders so guests are nudged before and after the due date.'),
        findsOneWidget,
      );
      expect(find.text('Add reminder'), findsOneWidget);
      expect(find.byIcon(AppIcons.bell), findsOneWidget);
    });

    testWidgets('Renders list of reminders with correct timing labels and toggle switches', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockOwnerRepo()
        ..rules = [
          ReminderRule(
            id: 'r-1',
            pgId: 'pg-1',
            daysFromDue: -3,
            channel: 'push',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          ReminderRule(
            id: 'r-2',
            pgId: 'pg-1',
            daysFromDue: -1,
            channel: 'push',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          ReminderRule(
            id: 'r-3',
            pgId: 'pg-1',
            daysFromDue: 0,
            channel: 'push',
            isActive: false,
            createdAt: now,
            updatedAt: now,
          ),
          ReminderRule(
            id: 'r-4',
            pgId: 'pg-1',
            daysFromDue: 2,
            channel: 'push',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

      await tester.pumpWidget(createTestApp(ownerRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('3 days before the due date'), findsOneWidget);
      expect(find.text('1 day before the due date'), findsOneWidget);
      expect(find.text('On the due date'), findsOneWidget);
      expect(find.text('2 days after the due date'), findsOneWidget);
      expect(find.text('Push notification'), findsNWidgets(4));

      // Test toggling active switch on r-3
      final switches = find.byType(RuleSwitch);
      await tester.tap(switches.at(2)); // Tap switch of third rule
      await tester.pumpAndSettle();

      expect(repo.toggledRules['r-3'], isTrue);
    });

    testWidgets('Opens Add reminder sheet, selects On due date, and saves', (tester) async {
      final repo = MockOwnerRepo()..rules = [];

      await tester.pumpWidget(createTestApp(ownerRepo: repo));
      await tester.pumpAndSettle();

      // Tap top bar add icon
      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pumpAndSettle();

      // Check sheet opened
      expect(find.text('When'), findsOneWidget);
      expect(find.text('How'), findsOneWidget);
      expect(find.text('Before the due date'), findsOneWidget);
      expect(find.text('On the due date'), findsOneWidget);
      expect(find.text('After the due date'), findsOneWidget);

      // Select "On the due date"
      await tester.tap(find.text('On the due date'));
      await tester.pumpAndSettle();

      // Days field should be hidden
      expect(find.text('Days'), findsNothing);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.savedRules.length, 1);
      expect(repo.savedRules.first['daysFromDue'], 0);
      expect(repo.savedRules.first['channel'], 'push');
      expect(find.text('On the due date'), findsOneWidget);
    });

    testWidgets('Shows error when saving duplicate reminder rule', (tester) async {
      final repo = MockOwnerRepo()
        ..rules = []
        ..shouldThrowDuplicate = true;

      await tester.pumpWidget(createTestApp(ownerRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('You already have this reminder.'), findsOneWidget);
    });

    testWidgets('Opens Edit reminder sheet and removes rule with confirmation', (tester) async {
      final now = DateTime.now().toUtc();
      final repo = MockOwnerRepo()
        ..rules = [
          ReminderRule(
            id: 'r-delete',
            pgId: 'pg-1',
            daysFromDue: -5,
            channel: 'push',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

      await tester.pumpWidget(createTestApp(ownerRepo: repo));
      await tester.pumpAndSettle();

      // Tap rule row to open edit sheet
      await tester.tap(find.text('5 days before the due date'));
      await tester.pumpAndSettle();

      expect(find.text('Remove reminder'), findsOneWidget);

      // Tap remove reminder
      await tester.tap(find.text('Remove reminder'));
      await tester.pumpAndSettle();

      // ConfirmSheet appears
      expect(find.text('Are you sure you want to remove this reminder?'), findsOneWidget);

      // Confirm deletion (find the second 'Remove reminder' button which is in the confirm sheet)
      final removeButtons = find.text('Remove reminder');
      await tester.tap(removeButtons.last);
      await tester.pumpAndSettle();

      expect(repo.deletedIds, contains('r-delete'));
      expect(find.text('5 days before the due date'), findsNothing);
    });
  });
}
