import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_bottom_nav.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/guest/presentation/guest_shell.dart';
import 'package:app/features/owner/presentation/owner_shell.dart';

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<bool>.broadcast();
  bool _authenticated;
  AuthContext _context;
  String? _selectedPgId;

  FakeAuthRepository({
    bool authenticated = false,
    AuthContext context = const AuthContext.empty(),
    String? selectedPgId,
  })  : _authenticated = authenticated,
        _context = context,
        _selectedPgId = selectedPgId;

  @override
  Stream<bool> authStateChanges() => _controller.stream;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<AuthContext> getMyContext() async => _context;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {}

  @override
  Future<void> signOut() async {
    _authenticated = false;
    _context = const AuthContext.empty();
    _controller.add(false);
  }

  @override
  Future<String?> getSelectedPgId() async => _selectedPgId;

  @override
  Future<void> setSelectedPgId(String pgId) async {
    _selectedPgId = pgId;
  }

  @override
  Future<String?> getLastView() async => null;

  @override
  Future<void> setLastView(String view) async {}
}

Widget createTestApp({required FakeAuthRepository authRepo}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    ),
  );
}

void main() {
  group('N1 Navigation and Shells', () {
    testWidgets('Unauthenticated startup redirects to sign in screen',
        (tester) async {
      final authRepo = FakeAuthRepository(authenticated: false);

      await tester.pumpWidget(createTestApp(authRepo: authRepo));
      await tester.pumpAndSettle();

      expect(find.text('Enter your mobile number'), findsOneWidget);
      expect(find.byIcon(AppIcons.bell), findsNothing);
    });

    testWidgets('Neither owner nor guest redirects to role gate',
        (tester) async {
      final authRepo = FakeAuthRepository(
        authenticated: true,
        context: const AuthContext(
          person: AuthPerson(id: 'p1', phone: '+919999999999'),
          pgs: [],
          stays: [],
        ),
      );

      await tester.pumpWidget(createTestApp(authRepo: authRepo));
      await tester.pumpAndSettle();

      expect(find.text('How will you use PG App?'), findsOneWidget);
    });

    testWidgets(
        'Owner startup redirects to owner shell with 4 tabs and title only',
        (tester) async {
      final authRepo = FakeAuthRepository(
        authenticated: true,
        context: const AuthContext(
          person: AuthPerson(id: 'p1', phone: '+919999999999'),
          pgs: [AuthPg(pgId: 'pg1', name: 'Test PG', role: 'owner')],
          stays: [],
        ),
      );

      await tester.pumpWidget(createTestApp(authRepo: authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerShell), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);

      // Verify the 4 tabs exist
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Guests'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Bell icon is shown after S3 approval
      expect(find.byIcon(AppIcons.bell), findsWidgets);

      // Tap Guests tab
      await tester.tap(find.text('Guests'));
      await tester.pumpAndSettle();
      expect(find.text('Guests'), findsWidgets);

      // Tap Payments tab
      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();
      expect(find.text('Payments'), findsWidgets);

      // Tap More tab
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('More'), findsWidgets);
    });

    testWidgets(
        'Guest startup redirects to guest shell with 3 tabs and title only',
        (tester) async {
      final authRepo = FakeAuthRepository(
        authenticated: true,
        context: const AuthContext(
          person: AuthPerson(id: 'p2', phone: '+918888888888'),
          pgs: [],
          stays: [
            AuthStay(
              stayId: 's1',
              pgId: 'pg1',
              pgName: 'Test PG',
              status: 'active',
            ),
          ],
        ),
      );

      await tester.pumpWidget(createTestApp(authRepo: authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(GuestShell), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);

      // Verify 3 tabs exist
      expect(find.text('Home'), findsWidgets);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Bell icon is shown after S3 approval
      expect(find.byIcon(AppIcons.bell), findsWidgets);

      // Tap History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsWidgets);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
    });
  });
}

