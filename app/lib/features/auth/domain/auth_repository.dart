import 'auth_context.dart';

class AuthRateLimitException implements Exception {
  const AuthRateLimitException();
}

class AuthNetworkException implements Exception {
  const AuthNetworkException();
}

class AuthInvalidOtpException implements Exception {
  const AuthInvalidOtpException();
}

class AuthOtpExpiredException implements Exception {
  const AuthOtpExpiredException();
}

abstract class AuthRepository {
  Stream<bool> authStateChanges();
  bool get isAuthenticated;
  Future<AuthContext> getMyContext();
  Future<void> sendOtp(String phone);
  Future<void> verifyOtp({required String phone, required String token});
  Future<void> signOut();
  Future<String?> getSelectedPgId();
  Future<void> setSelectedPgId(String pgId);
  Future<String?> getLastView();
  Future<void> setLastView(String view);
}
