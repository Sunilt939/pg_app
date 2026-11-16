import 'auth_context.dart';

abstract class AuthRepository {
  Stream<bool> authStateChanges();
  bool get isAuthenticated;
  Future<AuthContext> getMyContext();
  Future<void> signOut();
  Future<String?> getSelectedPgId();
  Future<void> setSelectedPgId(String pgId);
}

