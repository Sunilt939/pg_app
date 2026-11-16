import 'auth_context.dart';

class AuthRateLimitException implements Exception {
  const AuthRateLimitException();
}

class AuthNetworkException implements Exception {
  const AuthNetworkException();
}

abstract class AuthRepository {
  Stream<bool> authStateChanges();
  bool get isAuthenticated;
  Future<AuthContext> getMyContext();
  Future<void> sendOtp(String phone);
  Future<void> signOut();
  Future<String?> getSelectedPgId();
  Future<void> setSelectedPgId(String pgId);
}
