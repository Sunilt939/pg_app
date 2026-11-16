import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/presentation/screens/sign_in_screen.dart';

class MockAuthRepo implements AuthRepository {
  String? sentPhone;
  bool shouldThrowRateLimit = false;
  bool shouldThrowNetwork = false;
  bool shouldThrowGeneric = false;
  Completer<void>? pendingSend;

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => false;

  @override
  Future<AuthContext> getMyContext() async => const AuthContext.empty();

  @override
  Future<void> sendOtp(String phone) async {
    sentPhone = phone;
    if (pendingSend != null) {
      await pendingSend!.future;
    }
    if (shouldThrowRateLimit) {
      throw const AuthRateLimitException();
    }
    if (shouldThrowNetwork) {
      throw const AuthNetworkException();
    }
    if (shouldThrowGeneric) {
      throw Exception('Database down');
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getSelectedPgId() async => null;

  @override
  Future<void> setSelectedPgId(String pgId) async {}
}

Widget createSignInTestWidget({
  required MockAuthRepo authRepo,
  List<RouteBase>? extraRoutes,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.signIn,
    routes: [
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.verify,
        builder: (context, state) => Scaffold(
          body: Text('VERIFY_SCREEN:${state.extra}'),
        ),
      ),
      ...?extraRoutes,
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('A1. Sign-in Screen', () {
    testWidgets('renders initial components, headlines and disabled button',
        (tester) async {
      final repo = MockAuthRepo();
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Your PG, in order.'), findsOneWidget);
      expect(
        find.text('Rent, receipts and reminders in one place.'),
        findsOneWidget,
      );
      expect(find.text('Enter your mobile number'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('10-digit mobile number'), findsOneWidget);
      expect(find.text("We'll send a 6-digit code by SMS."), findsOneWidget);

      final sendBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(sendBtn.onPressed, isNull);
    });

    testWidgets('shows invalid error immediately when first digit is 0 to 5',
        (tester) async {
      final repo = MockAuthRepo();
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '5');
      await tester.pump();

      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );

      final sendBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(sendBtn.onPressed, isNull);
    });

    testWidgets('shows invalid error on blur if digits are incomplete',
        (tester) async {
      final repo = MockAuthRepo();
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '98765');
      await tester.pump();

      // No error while typing starting with 9
      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsNothing,
      );

      // Unfocus field to trigger blur
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();

      // Error appears on lost focus
      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );

      final sendBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(sendBtn.onPressed, isNull);
    });

    testWidgets('enables button with valid 10-digit number and navigates on submit',
        (tester) async {
      final repo = MockAuthRepo();
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '9876543210');
      await tester.pump();

      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsNothing,
      );

      final sendBtn = tester.widget<AppButton>(find.byType(AppButton));
      expect(sendBtn.onPressed, isNotNull);

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(repo.sentPhone, '+919876543210');
      expect(find.text('VERIFY_SCREEN:+919876543210'), findsOneWidget);
    });

    testWidgets('shows tooManyAttempts error under field when rate limited',
        (tester) async {
      final repo = MockAuthRepo()..shouldThrowRateLimit = true;
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '9876543210');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many attempts. Please wait a few minutes and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows network error snackbar on connection failure',
        (tester) async {
      final repo = MockAuthRepo()..shouldThrowNetwork = true;
      await tester.pumpWidget(createSignInTestWidget(authRepo: repo));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '9876543210');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('No internet connection. Check your connection and try again.'),
        findsOneWidget,
      );
    });
  });
}
