import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_context.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

class AuthContextNotifier extends AsyncNotifier<AuthContext> {
  @override
  Future<AuthContext> build() async {
    final repo = ref.watch(authRepositoryProvider);
    if (!repo.isAuthenticated) {
      return const AuthContext.empty();
    }
    try {
      return await repo.getMyContext();
    } catch (_) {
      return const AuthContext.empty();
    }
  }

  Future<void> refreshContext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      if (!repo.isAuthenticated) {
        return const AuthContext.empty();
      }
      return repo.getMyContext();
    });
  }
}

final authContextProvider =
    AsyncNotifierProvider<AuthContextNotifier, AuthContext>(
  AuthContextNotifier.new,
);

class SelectedPgIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final stored = await repo.getSelectedPgId();
    final authContext = ref.watch(authContextProvider).valueOrNull;
    final pgs = authContext?.pgs ?? [];
    if (pgs.isEmpty) return stored;

    if (stored != null && pgs.any((p) => p.pgId == stored)) {
      return stored;
    }
    final firstId = pgs.first.pgId;
    await repo.setSelectedPgId(firstId);
    return firstId;
  }

  Future<void> setPgId(String pgId) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.setSelectedPgId(pgId);
    state = AsyncData(pgId);
  }
}

final selectedPgIdProvider =
    AsyncNotifierProvider<SelectedPgIdNotifier, String?>(
  SelectedPgIdNotifier.new,
);

final activePgProvider = Provider<AuthPg?>((ref) {
  final authContext = ref.watch(authContextProvider).valueOrNull;
  final pgs = authContext?.pgs ?? [];
  if (pgs.isEmpty) return null;
  final selectedId = ref.watch(selectedPgIdProvider).valueOrNull;
  if (selectedId == null) return pgs.first;
  return pgs.firstWhere(
    (p) => p.pgId == selectedId,
    orElse: () => pgs.first,
  );
});

