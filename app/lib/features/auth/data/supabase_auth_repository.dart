import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_context.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _explicitClient;
  final FlutterSecureStorage _storage;

  static const _selectedPgKey = 'selected_pg_id';

  SupabaseAuthRepository({
    SupabaseClient? client,
    FlutterSecureStorage? storage,
  })  : _explicitClient = client,
        _storage = storage ?? const FlutterSecureStorage();

  SupabaseClient? get _client {
    if (_explicitClient != null) {
      return _explicitClient;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<bool> authStateChanges() {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange.map((data) => data.session != null);
  }

  @override
  bool get isAuthenticated {
    final client = _client;
    return client?.auth.currentSession != null;
  }

  @override
  Future<AuthContext> getMyContext() async {
    final client = _client;
    if (client == null) {
      return const AuthContext.empty();
    }
    final response = await client.rpc('rpc_my_context');
    if (response == null) {
      return const AuthContext.empty();
    }
    return AuthContext.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    await _storage.delete(key: _selectedPgKey);
  }

  @override
  Future<String?> getSelectedPgId() async {
    try {
      return await _storage.read(key: _selectedPgKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setSelectedPgId(String pgId) async {
    try {
      await _storage.write(key: _selectedPgKey, value: pgId);
    } catch (_) {
      // Ignored if storage is unavailable in test environment
    }
  }
}
