import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:app/features/auth/presentation/screens/gate_guest_screen.dart';

class MockGateGuestAuthRepo implements AuthRepository {
  bool signOutCalled = false;
  int getMyContextCallCount = 0;
  AuthContext myContext = const AuthContext(
    person: AuthPerson(
      id: 'person-guest-1',
      phone: '+919876543210',
    ),
    stays: [],
  );

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthContext> getMyContext() async {
    getMyContextCallCount++;
    return myContext;
  }

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
  required MockGateGuestAuthRepo repo,
  List<RouteBase> extraRoutes = const [],
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.gateGuest,
    routes: [
      GoRoute(
        path: RoutePaths.gateGuest,
        builder: (context, state) => const GateGuestScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const Scaffold(body: Text('Sign In Screen')),
      ),
      GoRoute(
        path: RoutePaths.guestHome,
        builder: (context, state) => const Scaffold(body: Text('Guest Home Screen')),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GateGuestScreen renders title, body, number sheet, check again, and sign out',
      (tester) async {
    final repo = MockGateGuestAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ask your PG owner to add you'), findsOneWidget);
    expect(
      find.text("Your number isn't registered yet. Please ask your PG owner to add you."),
      findsOneWidget,
    );
    expect(find.text('Your number'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.byIcon(AppIcons.copy), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Tapping copy copies number to clipboard and shows snackbar',
      (tester) async {
    final repo = MockGateGuestAuthRepo();

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText = (methodCall.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.copy));
    await tester.pump();

    expect(copiedText, equals('+91 98765 43210'));
    expect(find.text('Number copied.'), findsOneWidget);
  });

  testWidgets('Tapping Check again when still not added shows stillNotAdded snackbar',
      (tester) async {
    final repo = MockGateGuestAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check again'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.getMyContextCallCount, greaterThan(0));
    expect(
      find.text('Still not added. Ask your PG owner to check the number.'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping Check again when guest stay is added routes to guest home',
      (tester) async {
    final repo = MockGateGuestAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    // Owner now adds guest
    repo.myContext = const AuthContext(
      person: AuthPerson(
        id: 'person-guest-1',
        phone: '+919876543210',
      ),
      stays: [
        AuthStay(
          stayId: 'stay-123',
          pgId: 'pg-123',
          pgName: 'Sunshine PG',
          status: 'active',
        ),
      ],
    );

    await tester.tap(find.text('Check again'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Guest Home Screen'), findsOneWidget);
  });

  testWidgets('Tapping Sign out calls signOut and navigates to sign-in',
      (tester) async {
    final repo = MockGateGuestAuthRepo();

    await tester.pumpWidget(createTestApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalled, isTrue);
    expect(find.text('Sign In Screen'), findsOneWidget);
  });
}
