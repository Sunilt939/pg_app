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

final selectedPgIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getSelectedPgId();
});

