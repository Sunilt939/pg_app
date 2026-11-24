import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/l10n/app_localizations.dart';
import 'package:app/core/router/route_paths.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_button.dart';
import 'package:app/core/widgets/profile_avatar.dart';
import 'package:app/features/auth/domain/auth_context.dart';
import 'package:app/features/auth/domain/auth_repository.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/owner/domain/guest_list_item.dart';
import 'package:app/features/shared/domain/emergency_contact.dart';
import 'package:app/features/shared/domain/profile_repository.dart';
import 'package:app/features/shared/presentation/providers/profile_provider.dart';
import 'package:app/features/shared/presentation/screens/profile_screen.dart';

class MockProfileRepo implements ProfileRepository {
  final MockAuthRepo? authRepo;
  String? updatedName;
  String? updatedEmail;

  MockProfileRepo([this.authRepo]);

  @override
  Future<void> updateName(String fullName) async {
    updatedName = fullName;
    if (authRepo != null) {
      final old = authRepo!.myContext;
      authRepo!.myContext = AuthContext(
        person: AuthPerson(
          id: old.person!.id,
          phone: old.person!.phone,
          fullName: fullName,
          email: old.person!.email,
        ),
        pgs: old.pgs,
        stays: old.stays,
      );
    }
  }

  @override
  Future<void> updateEmail(String? email) async {
    updatedEmail = email;
    if (authRepo != null) {
      final old = authRepo!.myContext;
      authRepo!.myContext = AuthContext(
        person: AuthPerson(
          id: old.person!.id,
          phone: old.person!.phone,
          fullName: old.person!.fullName,
          email: email,
        ),
        pgs: old.pgs,
        stays: old.stays,
      );
    }
  }

  String? photoPath;
  String? presetId;

  @override
  Future<String?> getProfilePhotoPath() async => photoPath;

  @override
  Future<String?> getPresetAvatarId() async => presetId;

  @override
  Future<void> updateProfilePhoto(String filePath) async {
    photoPath = filePath;
    presetId = null;
  }

  @override
  Future<void> updatePresetAvatar(String id) async {
    presetId = id;
    photoPath = null;
  }

  @override
  Future<void> removeProfilePhoto() async {
    photoPath = null;
    presetId = null;
  }

  List<EmergencyContact> emergencyContacts = [];
  List<RelationshipType> relationshipTypes = [];
  GuestListItem? guestOpenStay;

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async => emergencyContacts;

  @override
  Future<List<RelationshipType>> getRelationshipTypes() async =>
      relationshipTypes;

  @override
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    emergencyContacts.add(EmergencyContact(
      id: 'contact-${emergencyContacts.length + 1}',
      personId: 'person-1',
      name: name,
      phone: phone,
      relationshipTypeId: relationshipTypeId,
      isPrimary: isPrimary,
    ));
  }

  @override
  Future<void> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    int? relationshipTypeId,
    bool isPrimary = false,
  }) async {
    final idx = emergencyContacts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      emergencyContacts[idx] = EmergencyContact(
        id: id,
        personId: emergencyContacts[idx].personId,
        name: name,
        phone: phone,
        relationshipTypeId: relationshipTypeId,
        isPrimary: isPrimary,
      );
    }
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    emergencyContacts.removeWhere((c) => c.id == id);
  }

  @override
  Future<GuestListItem?> getGuestOpenStay() async => guestOpenStay;
}

class MockAuthRepo implements AuthRepository {
  bool signOutCalled = false;
  AuthContext myContext;

  MockAuthRepo({
    this.myContext = const AuthContext(
      person: AuthPerson(
        id: 'person-1',
        phone: '+919876543210',
        fullName: 'Ravi Kumar',
        email: 'ravi@example.com',
      ),
      pgs: [
        AuthPg(pgId: 'pg-1', name: 'Sunrise PG', role: 'owner'),
      ],
    ),
  });

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
  Future<String?> getSelectedPgId() async => 'pg-1';

  @override
  Future<void> setSelectedPgId(String pgId) async {}

  @override
  Future<String?> getLastView() async => 'owner';

  @override
  Future<void> setLastView(String view) async {}
}

Widget _wrapWithRouter({
  required WidgetRef ref,
  required Widget child,
}) {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const Scaffold(
          body: Text('Sign In Page'),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  testWidgets('ProfileScreen displays header, details, and sign out',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify name and phone in header
    expect(find.text('Ravi Kumar'), findsNWidgets(2)); // Header + Details row
    expect(find.text('+91 98765 43210'), findsNWidgets(2)); // Header + Details row
    expect(find.text('ravi@example.com'), findsOneWidget);
    expect(find.text('Your details'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Tapping mobile number shows locked snackbar', (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap mobile number row (second instance of phone)
    await tester.tap(find.text('+91 98765 43210').last);
    await tester.pump();

    expect(
      find.text("Your mobile number can't be changed here."),
      findsOneWidget,
    );
  });

  testWidgets('Editing name validates required field and updates name',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the Name row
    await tester.tap(find.text('Ravi Kumar').last);
    await tester.pumpAndSettle();

    // Bottom sheet is open with text field
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Clear text field and tap Save
    await tester.enterText(textFieldFinder, '');
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    // Error is shown
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(mockProfile.updatedName, isNull);

    // Enter valid name and tap Save
    await tester.enterText(textFieldFinder, 'Ravi Teja');
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    expect(mockProfile.updatedName, equals('Ravi Teja'));
    expect(find.byType(TextField), findsNothing); // Sheet closed
    expect(find.text('Name updated'), findsOneWidget);
    expect(find.text('Ravi Teja'), findsNWidgets(2));
  });

  testWidgets('Editing email validates format and updates email',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the Email row
    await tester.tap(find.text('ravi@example.com'));
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Enter invalid email and tap Save
    await tester.enterText(textFieldFinder, 'not-an-email');
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    // Error is shown
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(mockProfile.updatedEmail, isNull);

    // Enter valid email and tap Save
    await tester.enterText(textFieldFinder, 'new.email@example.com');
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    expect(mockProfile.updatedEmail, equals('new.email@example.com'));
    expect(find.byType(TextField), findsNothing); // Sheet closed
    expect(find.text('Email updated'), findsOneWidget);
    expect(find.text('new.email@example.com'), findsOneWidget);
  });

  testWidgets(
      'Tapping profile avatar opens photo sheet and selecting preset updates avatar',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the avatar
    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();

    // Photo sheet opens with title and default avatars
    expect(find.text('Profile photo'), findsOneWidget);
    expect(find.text('Choose a default avatar'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);

    // Tap first default avatar in the list
    await tester.tap(find.byKey(const ValueKey('avatar_user')));
    await tester.pumpAndSettle();

    expect(mockProfile.presetId, isNotNull);
    expect(find.text('Profile photo updated'), findsOneWidget);
  });

  testWidgets('Sign out from Profile opens ConfirmSheet and signs out',
      (tester) async {
    final mockAuth = MockAuthRepo();
    final mockProfile = MockProfileRepo(mockAuth);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
        child: Consumer(
          builder: (context, ref, _) => _wrapWithRouter(
            ref: ref,
            child: const ProfileScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Sign out" button
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();

    // ConfirmSheet should appear
    expect(find.text('Sign out of PG App?'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(mockAuth.signOutCalled, isFalse);

    // Tap "Sign out" again and confirm
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();

    // Tap primary Sign out in sheet
    await tester.tap(find.widgetWithText(AppButton, 'Sign out').last);
    await tester.pumpAndSettle();

    expect(mockAuth.signOutCalled, isTrue);
    expect(find.text('Sign In Page'), findsOneWidget);
  });
}

