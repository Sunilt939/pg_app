import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/otp_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/presentation/screens/verify_screen.dart';

class MockVerifyAuthRepo implements AuthRepository {
  String? verifyPhone;
  String? verifyToken;
  String? sentPhone;

  bool throwInvalid = false;
  bool throwExpired = false;
  bool throwNetwork = false;

  AuthContext myContext = const AuthContext.empty();
  String? lastView;

  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => false;

  @override
  Future<AuthContext> getMyContext() async => myContext;

  @override
  Future<void> sendOtp(String phone) async {
    sentPhone = phone;
  }

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {
    verifyPhone = phone;
    verifyToken = token;

    if (throwInvalid) {
      throw const AuthInvalidOtpException();
    }
    if (throwExpired) {
      throw const AuthOtpExpiredException();
    }
    if (throwNetwork) {
      throw const AuthNetworkException();
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getSelectedPgId() async => null;

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => lastView;

  @override
  Future<void> setLastView(String view) async {
    lastView = view;
  }
}

Widget createVerifyTestWidget({
  required MockVerifyAuthRepo authRepo,
  String phone = '+919876543210',
  List<RouteBase>? extraRoutes,
}) {
  final router = GoRouter(
    initialLocation: '/test-verify',
    routes: [
      GoRoute(
        path: '/test-verify',
        builder: (context, state) => VerifyScreen(phone: phone),
      ),
      GoRoute(
        path: RoutePaths.ownerHome,
        builder: (context, state) => const Scaffold(body: Text('OWNER_HOME')),
      ),
      GoRoute(
        path: RoutePaths.guestHome,
        builder: (context, state) => const Scaffold(body: Text('GUEST_HOME')),
      ),
      GoRoute(
        path: RoutePaths.gate,
        builder: (context, state) => const Scaffold(body: Text('GATE_SCREEN')),
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
  group('A2. Enter Code Screen', () {
    testWidgets('renders initial components, formatted phone and resend timer',
        (tester) async {
      final repo = MockVerifyAuthRepo();
      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(find.text('Sent to +91 98765 43210'), findsOneWidget);
      expect(find.text('Change number'), findsOneWidget);
      expect(find.byType(OtpField), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Resend code in 0:30'), findsOneWidget);

      final verifyBtn = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Verify'),
      );
      expect(verifyBtn.onPressed, isNull);

      // Clean up timer
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('submits code when 6 digits are entered and navigates to owner home',
        (tester) async {
      final repo = MockVerifyAuthRepo()
        ..myContext = const AuthContext(
          person: AuthPerson(id: 'p1', phone: '+919876543210'),
          pgs: [AuthPg(pgId: 'pg1', name: 'My PG', role: 'owner')],
          stays: [],
        );

      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '123456');
      await tester.pumpAndSettle();

      expect(repo.verifyPhone, '+919876543210');
      expect(repo.verifyToken, '123456');
      expect(find.text('OWNER_HOME'), findsOneWidget);
    });

    testWidgets('navigates to guest home when signed in user has stays',
        (tester) async {
      final repo = MockVerifyAuthRepo()
        ..myContext = const AuthContext(
          person: AuthPerson(id: 'p2', phone: '+919876543210'),
          pgs: [],
          stays: [
            AuthStay(
              stayId: 's1',
              pgId: 'pg1',
              pgName: 'Guest PG',
              status: 'active',
            ),
          ],
        );

      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '654321');
      await tester.pumpAndSettle();

      expect(find.text('GUEST_HOME'), findsOneWidget);
    });

    testWidgets('shows otpInvalid error and clears input on wrong OTP',
        (tester) async {
      final repo = MockVerifyAuthRepo()..throwInvalid = true;

      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '000000');
      await tester.pumpAndSettle();

      expect(
        find.text("That code isn't right. Check the SMS and try again."),
        findsOneWidget,
      );

      final otpField = tester.widget<OtpField>(find.byType(OtpField));
      expect(otpField.hasError, isTrue);

      // Clean up timer
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('shows otpExpired error on expired OTP', (tester) async {
      final repo = MockVerifyAuthRepo()..throwExpired = true;

      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '111111');
      await tester.pumpAndSettle();

      expect(
        find.text('That code has expired. Request a new one.'),
        findsOneWidget,
      );

      // Clean up timer
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('resend countdown transitions to resend button and restarts timer on tap',
        (tester) async {
      final repo = MockVerifyAuthRepo();

      await tester.pumpWidget(createVerifyTestWidget(authRepo: repo));
      await tester.pump();

      expect(find.text('Resend code in 0:30'), findsOneWidget);

      // Advance 15 seconds
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('Resend code in 0:15'), findsOneWidget);

      // Advance 16 more seconds to reach 0
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('Resend code'), findsOneWidget);

      // Tap Resend code
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();

      expect(repo.sentPhone, '+919876543210');
      expect(find.text('Code sent.'), findsOneWidget);
      expect(find.text('Resend code in 0:30'), findsOneWidget);

      // Clean up timer
      await tester.pump(const Duration(seconds: 31));
    });
  });
}

