import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_context.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _explicitClient;
  final FlutterSecureStorage _storage;

  static const _selectedPgKey = 'selected_pg_id';
  static const _lastViewKey = 'last_view';

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
    final map = Map<String, dynamic>.from(response as Map);
    final currentPhone = client.auth.currentUser?.phone;
    if (currentPhone != null && currentPhone.isNotEmpty) {
      if (map['person'] == null) {
        map['person'] = {
          'id': client.auth.currentUser!.id,
          'phone': currentPhone,
        };
      } else if (map['person'] is Map) {
        final personMap = Map<String, dynamic>.from(map['person'] as Map);
        if (personMap['phone'] == null || (personMap['phone'] as String).isEmpty) {
          personMap['phone'] = currentPhone;
          map['person'] = personMap;
        }
      }
    }
    return AuthContext.fromJson(map);
  }

  @override
  Future<void> sendOtp(String phone) async {
    final client = _client;
    if (client == null) {
      throw const AuthNetworkException();
    }
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    try {
      await client.auth.signInWithOtp(
        phone: formattedPhone,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.statusCode == '429' ||
          msg.contains('rate') ||
          msg.contains('too many')) {
        throw const AuthRateLimitException();
      }
      rethrow;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socket') ||
          str.contains('network') ||
          str.contains('connection') ||
          str.contains('clientexception')) {
        throw const AuthNetworkException();
      }
      rethrow;
    }
  }

  @override
  Future<void> verifyOtp({required String phone, required String token}) async {
    final client = _client;
    if (client == null) {
      throw const AuthNetworkException();
    }
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    try {
      await client.auth.verifyOTP(
        phone: formattedPhone,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      // Supabase returns "Token has expired or is invalid" for wrong tokens.
      // Treat general invalid/wrong token errors as AuthInvalidOtpException.
      if (msg.contains('invalid') ||
          msg.contains('wrong') ||
          msg.contains('token has expired or is invalid')) {
        throw const AuthInvalidOtpException();
      }
      if (msg.contains('expired')) {
        throw const AuthOtpExpiredException();
      }
      if (msg.contains('token') ||
          msg.contains('code') ||
          msg.contains('error')) {
        throw const AuthInvalidOtpException();
      }
      rethrow;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('socket') ||
          str.contains('network') ||
          str.contains('connection') ||
          str.contains('clientexception')) {
        throw const AuthNetworkException();
      }
      rethrow;
    }
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

  @override
  Future<String?> getLastView() async {
    try {
      return await _storage.read(key: _lastViewKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setLastView(String view) async {
    try {
      await _storage.write(key: _lastViewKey, value: view);
    } catch (_) {
      // Ignored if storage is unavailable in test environment
    }
  }
}
