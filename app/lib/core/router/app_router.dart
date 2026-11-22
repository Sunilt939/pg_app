import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dev/component_gallery.dart';
import '../../features/auth/domain/auth_context.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/gate_guest_screen.dart';
import '../../features/auth/presentation/screens/role_gate_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/verify_screen.dart';
import '../../features/guest/presentation/guest_shell.dart';
import '../../features/guest/presentation/screens/guest_history_screen.dart';
import '../../features/guest/presentation/screens/guest_home_screen.dart';
import '../../features/owner/presentation/owner_shell.dart';
import '../../features/owner/presentation/screens/add_pg_screen.dart';
import '../../features/owner/presentation/screens/add_guest_screen.dart';
import '../../features/owner/presentation/screens/add_rooms_screen.dart';
import '../../features/owner/presentation/screens/owner_account_form_screen.dart';
import '../../features/owner/presentation/screens/owner_accounts_screen.dart';
import '../../features/owner/presentation/screens/set_up_rooms_screen.dart';
import '../../features/owner/presentation/screens/owner_guests_screen.dart';
import '../../features/owner/presentation/screens/owner_home_screen.dart';
import '../../features/owner/presentation/screens/owner_more_screen.dart';
import '../../features/owner/presentation/screens/owner_payments_screen.dart';
import '../../features/owner/presentation/screens/owner_rooms_screen.dart';
import '../../features/owner/presentation/screens/owner_room_detail_screen.dart';
import '../../features/shared/presentation/screens/notifications_screen.dart';
import '../../features/shared/presentation/screens/placeholder_screen.dart';
import '../../features/shared/presentation/screens/profile_screen.dart';
import '../../features/shared/presentation/screens/receipt_screen.dart';
import '../l10n/app_localizations.dart';
import 'route_paths.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(authContextProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;

    if (kDebugMode && location == RoutePaths.devGallery) {
      return null;
    }

    final authRepo = _ref.read(authRepositoryProvider);
    final isAuthenticated = authRepo.isAuthenticated;

    final isAuthRoute = location == RoutePaths.signIn ||
        location == RoutePaths.verify ||
        location == RoutePaths.startup;

    if (!isAuthenticated) {
      if (isAuthRoute) {
        if (location == RoutePaths.startup) {
          return RoutePaths.signIn;
        }
        return null;
      }
      return RoutePaths.signIn;
    }

    final authContext = _ref.read(authContextProvider).valueOrNull ??
        const AuthContext.empty();

    if (location == RoutePaths.startup ||
        location == RoutePaths.signIn ||
        location == RoutePaths.verify) {
      if (authContext.isOwner) {
        return RoutePaths.ownerHome;
      } else if (authContext.isGuest) {
        return RoutePaths.guestHome;
      } else if (authContext.isNeither) {
        return RoutePaths.gate;
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.startup,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: RoutePaths.startup,
        builder: (context, state) => const Scaffold(
          body: SizedBox.expand(),
        ),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.verify,
        builder: (context, state) => VerifyScreen(
          phone: state.extra as String?,
        ),
      ),
      GoRoute(
        path: RoutePaths.gate,
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.gateGuest,
        builder: (context, state) => const GateGuestScreen(),
      ),
      GoRoute(
        path: RoutePaths.ownerPgNew,
        builder: (context, state) => const AddPgScreen(),
      ),
      GoRoute(
        path: RoutePaths.receipt,
        builder: (context, state) => ReceiptScreen(
          paymentId: state.pathParameters['paymentId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: RoutePaths.devGallery,
          builder: (context, state) => const ComponentGallery(),
        ),

      // Owner Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OwnerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerHome,
                builder: (context, state) => const OwnerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerGuests,
                builder: (context, state) => const OwnerGuestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerPayments,
                builder: (context, state) => const OwnerPaymentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerMore,
                builder: (context, state) => const OwnerMoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // Owner Subroutes (full screen overlay over shell)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerGuestsNew,
        builder: (context, state) => AddGuestScreen(
          initialBedId: state.uri.queryParameters['bedId'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerGuestDetail,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.guestsTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerGuestPay,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.payTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerPaymentDetail,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.paymentTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerCollections,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.collectionsTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerRooms,
        builder: (context, state) => const OwnerRoomsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerRoomsSetup,
        builder: (context, state) => const SetUpRoomsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerRoomsNew,
        builder: (context, state) => const AddRoomsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerRoomDetail,
        builder: (context, state) => OwnerRoomDetailScreen(
          roomId: state.pathParameters['roomId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerAccounts,
        builder: (context, state) => const OwnerAccountsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerAccountsNew,
        builder: (context, state) => const OwnerAccountFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerAccountDetail,
        builder: (context, state) => OwnerAccountFormScreen(
          accountId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerReminders,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.remindersTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.ownerSettings,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.pgDetailsTitle,
        ),
      ),

      // Guest Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return GuestShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.guestHome,
                builder: (context, state) => const GuestHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.guestHistory,
                builder: (context, state) => const GuestHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.guestProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Guest Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.guestPay,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.payTitle,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.guestStay,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context)!.historyTitle,
        ),
      ),
    ],
  );
});

