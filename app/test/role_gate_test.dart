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
import 'package:app/features/auth/presentation/screens/role_gate_screen.dart';

class MockRoleGateAuthRepo implements AuthRepository {
  bool signOutCalled = false;
  AuthContext myContext = const AuthContext(
    person: AuthPerson(
      id: 'person-1',
      phone: '+919876543210',
    ),
  );

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthContext> getMyContext() async => myContext;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {}

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<String?> getSelectedPgId() async => null;

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => null;

  @override
  Future<void> setLastView(String view) async {}
}

Widget createTestApp({
  required MockRoleGateAuthRepo repo,
  List<RouteBase> extraRoutes = const [],
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.gate,
    routes: [
      GoRoute(
        path: RoutePaths.gate,
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const Scaffold(body: Text('Sign In Screen')),
      ),
      GoRoute(
        path: RoutePaths.ownerPgNew,
        builder: (context, state) => const Scaffold(body: Text('Owner PG New Screen')),
      ),
      GoRoute(
        path: RoutePaths.gateGuest,
        builder: (context, state) => const Scaffold(body: Text('Gate Guest Screen')),
      ),
      ...extraRoutes,
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
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
  testWidgets('RoleGateScreen renders title, phone, options, and sign out button',
      (tester) async {
    final repo = MockRoleGateAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('How will you use PG App?'), findsOneWidget);
    expect(find.text('Signed in as +91 98765 43210'), findsOneWidget);
    expect(find.text('I run a PG'), findsOneWidget);
    expect(find.text('Create your PG and add your guests.'), findsOneWidget);
    expect(find.text("I'm a guest"), findsOneWidget);
    expect(
      find.text('Your PG owner adds you using your mobile number.'),
      findsOneWidget,
    );
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.byIcon(AppIcons.building), findsOneWidget);
    expect(find.byIcon(AppIcons.user), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(2));
  });

  testWidgets('Tapping "I run a PG" pushes owner PG new route', (tester) async {
    final repo = MockRoleGateAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I run a PG'));
    await tester.pumpAndSettle();

    expect(find.text('Owner PG New Screen'), findsOneWidget);
  });

  testWidgets('Tapping "I\'m a guest" pushes gate guest route', (tester) async {
    final repo = MockRoleGateAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a guest"));
    await tester.pumpAndSettle();

    expect(find.text('Gate Guest Screen'), findsOneWidget);
  });

  testWidgets('Tapping "Sign out" calls signOut and navigates to sign-in',
      (tester) async {
    final repo = MockRoleGateAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalled, isTrue);
    expect(find.text('Sign In Screen'), findsOneWidget);
  });
}

