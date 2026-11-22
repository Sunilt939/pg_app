import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_icons.dart';
import 'package:app/core/widgets/app_text_field.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/bed_occupancy.dart';
import 'package:app/features/owner/domain/city.dart';
import 'package:app/features/owner/domain/owner_repository.dart';
import 'package:app/features/owner/domain/payment_account.dart';
import 'package:app/features/owner/domain/pg_switcher_item.dart';
import 'package:app/features/owner/domain/room_type.dart';
import 'package:app/features/owner/presentation/providers/owner_provider.dart';
import 'package:app/features/owner/presentation/screens/owner_account_form_screen.dart';
import 'package:app/features/owner/presentation/screens/owner_accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockOwnerRepo implements OwnerRepository {
  List<PaymentAccount> accounts = [];
  bool throwDuplicate = false;
  PaymentAccount? lastCreated;
  PaymentAccount? lastUpdated;

  @override
  Future<List<PaymentAccount>> getPaymentAccounts(String pgId) async => accounts;

  @override
  Future<PaymentAccount?> getPaymentAccount(String id) async {
    final matches = accounts.where((a) => a.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<PaymentAccount> createPaymentAccount(PaymentAccount account) async {
    if (throwDuplicate) {
      throw const DuplicateNicknameException();
    }
    final created = account.copyWith(id: 'new-acc-${accounts.length + 1}');
    lastCreated = created;
    accounts.add(created);
    return created;
  }

  @override
  Future<PaymentAccount> updatePaymentAccount(PaymentAccount account) async {
    if (throwDuplicate) {
      throw const DuplicateNicknameException();
    }
    final existingIndex = accounts.indexWhere((a) => a.id == account.id);
    final wasDefault = existingIndex >= 0 && accounts[existingIndex].isDefault;

    final effectiveIsDefault = account.isActive && account.isDefault;
    final updatedAccount = account.copyWith(isDefault: effectiveIsDefault);
    lastUpdated = updatedAccount;

    if (effectiveIsDefault) {
      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i].pgId == account.pgId && accounts[i].id != account.id) {
          accounts[i] = accounts[i].copyWith(isDefault: false);
        }
      }
    }

    if (existingIndex >= 0) {
      accounts[existingIndex] = updatedAccount;
    }

    if (wasDefault && !effectiveIsDefault) {
      final otherActiveIndex = accounts.indexWhere(
        (a) => a.pgId == account.pgId && a.id != account.id && a.isActive,
      );
      if (otherActiveIndex >= 0) {
        accounts[otherActiveIndex] =
            accounts[otherActiveIndex].copyWith(isDefault: true);
      }
    }

    return updatedAccount;
  }

  @override
  Future<List<City>> getCities() async => const [];

  @override
  Future<List<PgSwitcherItem>> getOwnerPgs() async => const [
        PgSwitcherItem(pgId: 'pg-1', name: 'Green PG', role: 'owner'),
      ];

  @override
  Future<List<RoomType>> getRoomTypes() async => const [];

  @override
  Future<List<BedOccupancy>> getBedOccupancy(String pgId) async => const [];

  @override
  Future<int> addRooms({
    required String pgId,
    required int firstRoomNumber,
    required int roomCount,
    required int bedsPerRoom,
    String? roomTypeCode,
    int? floor,
    String? prefix,
  }) async =>
      roomCount;

  @override
  Future<int> addRoomLayout({
    required String pgId,
    required List<Map<String, dynamic>> rooms,
  }) async =>
      rooms.length;

  @override
  Future<String> createPg({
    required String name,
    required String line1,
    required int cityId,
    String? pincode,
    String? area,
    String? contactPhone,
    String genderPolicy = 'any',
  }) async =>
      'new-pg-id';

  @override
  Future<String> createStay({
    required String pgId,
    required String phone,
    required String fullName,
    String? bedId,
    required DateTime joinDate,
    required int monthlyRentPaise,
    int depositPaise = 0,
    int? billingDay,
    DateTime? billingStartsOn,
    bool depositAlreadyPaid = false,
  }) async =>
      'stay-123';

  @override
  Future<List<GuestListItem>> getGuests({
    required String pgId,
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<PgOverview?> getPgOverview(String pgId) async => null;
}

class MockAuthRepo implements AuthRepository {
  @override
  Stream<bool> authStateChanges() => const Stream.empty();

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthContext> getMyContext() async => const AuthContext(
        person: AuthPerson(id: 'p-1', phone: '+919876543210'),
        pgs: [AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'owner')],
      );

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getSelectedPgId() async => 'pg-1';

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => 'owner';

  @override
  Future<void> setLastView(String view) async {}
}

Widget _buildTestApp({
  required MockOwnerRepo ownerRepo,
  required MockAuthRepo authRepo,
  String initialLocation = RoutePaths.ownerAccounts,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.ownerAccounts,
        builder: (context, state) => const OwnerAccountsScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerAccountsNew,
        builder: (context, state) => const OwnerAccountFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerAccountDetail,
        builder: (context, state) => OwnerAccountFormScreen(
          accountId: state.pathParameters['id'],
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      ownerRepositoryProvider.overrideWithValue(ownerRepo),
      authRepositoryProvider.overrideWithValue(authRepo),
      activePgProvider.overrideWithValue(
        const AuthPg(pgId: 'pg-1', name: 'Green PG', role: 'owner'),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('O14 Receiving Accounts - List', () {
    testWidgets('shows empty state when no accounts exist and button opens new form',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      final ownerRepo = MockOwnerRepo();
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receiving accounts'), findsOneWidget);
      expect(find.text('No receiving accounts yet'), findsOneWidget);
      expect(
        find.text('Add the UPI ID or bank account where guests send rent.'),
        findsOneWidget,
      );
      expect(find.text('Add account'), findsOneWidget);

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();

      expect(find.text('Nickname'), findsOneWidget);
      expect(find.text('Save account'), findsOneWidget);
    });

    testWidgets('shows accounts with UPI, bank, default and off chips, and opens edit on tap',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      final ownerRepo = MockOwnerRepo();
      ownerRepo.accounts = [
        const PaymentAccount(
          id: 'acc-1',
          pgId: 'pg-1',
          nickname: 'Personal UPI',
          kind: 'upi',
          upiVpa: 'owner@okhdfcbank',
          isDefault: true,
          isActive: true,
        ),
        const PaymentAccount(
          id: 'acc-2',
          pgId: 'pg-1',
          nickname: 'Current Account',
          kind: 'bank',
          bankName: 'HDFC Bank',
          accountLast4: '4321',
          isDefault: false,
          isActive: false,
        ),
        const PaymentAccount(
          id: 'acc-3',
          pgId: 'pg-1',
          nickname: 'Savings Account',
          kind: 'bank',
          bankName: 'ICICI Bank',
          isDefault: false,
          isActive: true,
        ),
      ];
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      // Row 1: UPI
      expect(find.text('Personal UPI'), findsOneWidget);
      expect(find.text('owner@okhdfcbank'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // Row 2: Bank with last4
      expect(find.text('Current Account'), findsOneWidget);
      expect(find.text('HDFC Bank, ending 4321'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);

      // Row 3: Bank without last4
      expect(find.text('Savings Account'), findsOneWidget);
      expect(find.text('ICICI Bank'), findsOneWidget);

      // Tapping row 1 opens edit form
      await tester.tap(find.text('Personal UPI'));
      await tester.pumpAndSettle();

      expect(find.text('Save account'), findsOneWidget);
      expect(find.text('Personal UPI'), findsOneWidget);
      expect(find.text('owner@okhdfcbank'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('top bar plus button opens new account form', (tester) async {
      final ownerRepo = MockOwnerRepo();
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.plus));
      await tester.pumpAndSettle();

      expect(find.text('Save account'), findsOneWidget);
    });
  });

  group('O14 Receiving Accounts - Form (Create mode)', () {
    testWidgets('defaults Use as default to on when first account',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      final ownerRepo = MockOwnerRepo(); // accounts is empty
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: RoutePaths.ownerAccountsNew,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Use as default'), findsOneWidget);
      // "Active" switch should not appear in create mode
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('validates required nickname, UPI ID, and bank name',
        (tester) async {
      final ownerRepo = MockOwnerRepo();
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: RoutePaths.ownerAccountsNew,
      ));
      await tester.pumpAndSettle();

      // Submit empty
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a nickname.'), findsOneWidget);
      expect(
        find.text('Enter a valid UPI ID, for example name@bank.'),
        findsOneWidget,
      );

      // Switch to Bank type
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();

      // Submit again
      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a nickname.'), findsOneWidget);
      expect(find.text('Enter the bank name.'), findsOneWidget);
    });

    testWidgets('shows duplicate nickname error when 23505 occurs',
        (tester) async {
      final ownerRepo = MockOwnerRepo()..throwDuplicate = true;
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: RoutePaths.ownerAccountsNew,
      ));
      await tester.pumpAndSettle();

      // Fill valid nickname and UPI ID
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nickname'),
        'Existing Nickname',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'UPI ID'),
        'test@okhdfcbank',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(
        find.text('You already have an account with this nickname.'),
        findsOneWidget,
      );
    });

    testWidgets('creates UPI account and saves correctly', (tester) async {
      final ownerRepo = MockOwnerRepo();
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: RoutePaths.ownerAccountsNew,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nickname'),
        'Google Pay',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'UPI ID'),
        'owner@okaxis',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Name on the UPI ID (optional)'),
        'Ramesh Kumar',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(ownerRepo.lastCreated, isNotNull);
      expect(ownerRepo.lastCreated!.nickname, equals('Google Pay'));
      expect(ownerRepo.lastCreated!.kind, equals('upi'));
      expect(ownerRepo.lastCreated!.upiVpa, equals('owner@okaxis'));
      expect(ownerRepo.lastCreated!.holderName, equals('Ramesh Kumar'));
      expect(ownerRepo.lastCreated!.isDefault, isTrue); // First account defaults to true
      expect(ownerRepo.lastCreated!.isActive, isTrue);

      // Successfully popped back to accounts list
      expect(find.text('Google Pay'), findsOneWidget);
    });

    testWidgets('creates Bank account and saves correctly', (tester) async {
      final ownerRepo = MockOwnerRepo();
      ownerRepo.accounts = [
        const PaymentAccount(
          id: 'acc-1',
          pgId: 'pg-1',
          nickname: 'Existing UPI',
          kind: 'upi',
          upiVpa: 'test@upi',
          isDefault: true,
        ),
      ];
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: RoutePaths.ownerAccountsNew,
      ));
      await tester.pumpAndSettle();

      // Switch to Bank
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nickname'),
        'SBI Account',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Bank name'),
        'State Bank of India',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Last 4 digits of the account (optional)'),
        '9876',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Account holder name (optional)'),
        'Ramesh Kumar',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(ownerRepo.lastCreated, isNotNull);
      expect(ownerRepo.lastCreated!.nickname, equals('SBI Account'));
      expect(ownerRepo.lastCreated!.kind, equals('bank'));
      expect(ownerRepo.lastCreated!.bankName, equals('State Bank of India'));
      expect(ownerRepo.lastCreated!.accountLast4, equals('9876'));
      expect(ownerRepo.lastCreated!.holderName, equals('Ramesh Kumar'));
      expect(ownerRepo.lastCreated!.isDefault, isFalse); // Not first account
    });
  });

  group('O14 Receiving Accounts - Form (Edit mode)', () {
    testWidgets('loads account and allows updating default and active status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      final ownerRepo = MockOwnerRepo();
      ownerRepo.accounts = [
        const PaymentAccount(
          id: 'acc-1',
          pgId: 'pg-1',
          nickname: 'Old Nickname',
          kind: 'upi',
          upiVpa: 'old@bank',
          isDefault: false,
          isActive: true,
        ),
      ];
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: '/owner/accounts/acc-1',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Old Nickname'), findsOneWidget);
      expect(find.text('old@bank'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Edit nickname
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Nickname'),
        'Updated Nickname',
      );
      await tester.pumpAndSettle();

      // Scroll up to ensure switches are fully visible above bottom action bar
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Toggle Active to false (which also forces Use as default to false)
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      expect(ownerRepo.lastUpdated, isNotNull);
      expect(ownerRepo.lastUpdated!.nickname, equals('Updated Nickname'));
      expect(ownerRepo.lastUpdated!.isDefault, isFalse);
      expect(ownerRepo.lastUpdated!.isActive, isFalse);
    });

    testWidgets(
        'deactivating default account turns default off and transfers default to second active account',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      final ownerRepo = MockOwnerRepo();
      ownerRepo.accounts = [
        const PaymentAccount(
          id: 'acc-1',
          pgId: 'pg-1',
          nickname: 'UPI Default',
          kind: 'upi',
          upiVpa: 'upi@bank',
          isDefault: true,
          isActive: true,
        ),
        const PaymentAccount(
          id: 'acc-2',
          pgId: 'pg-1',
          nickname: 'Bank Second',
          kind: 'bank',
          bankName: 'HDFC',
          isDefault: false,
          isActive: true,
        ),
      ];
      final authRepo = MockAuthRepo();

      await tester.pumpWidget(_buildTestApp(
        ownerRepo: ownerRepo,
        authRepo: authRepo,
        initialLocation: '/owner/accounts/acc-1',
      ));
      await tester.pumpAndSettle();

      // Scroll to switches
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Toggle Active off
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      // Tapping Use as default while Active is off should not enable it
      await tester.tap(find.text('Use as default'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save account'));
      await tester.pumpAndSettle();

      // acc-1 is now inactive and not default
      expect(ownerRepo.accounts[0].isActive, isFalse);
      expect(ownerRepo.accounts[0].isDefault, isFalse);

      // acc-2 has inherited the default status
      expect(ownerRepo.accounts[1].isActive, isTrue);
      expect(ownerRepo.accounts[1].isDefault, isTrue);
    });
  });
}

