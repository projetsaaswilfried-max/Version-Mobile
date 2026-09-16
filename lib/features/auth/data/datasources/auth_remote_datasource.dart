abstract class AuthRemoteDataSource {
  ({String id, String email})? get currentUser;

  Stream<({String id, String email})?> get onAuthStateChange;

  Future<({String id, String email})> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  });

  Future<({String id, String email})> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> resendSignupEmail({required String email});

  Future<void> requestPasswordReset({required String email});

  Future<void> signOut();
}
