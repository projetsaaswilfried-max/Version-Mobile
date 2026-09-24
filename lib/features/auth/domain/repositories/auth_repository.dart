import '../../../../core/error/result.dart';
import '../entities/auth_deep_link_result.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  });

  /// No session until email confirmed (OTP or link).
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  });

  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<Result<void>> resendSignupEmail({required String email});

  Future<Result<void>> requestPasswordReset({required String email});

  /// Native Google Sign-In (no browser, no deep link) - the session is
  /// established synchronously.
  Future<Result<AuthSession>> signInWithGoogle();

  /// Native Sign in with Apple (iOS only) - required alongside Google by
  /// App Store review guideline 4.8.
  Future<Result<AuthSession>> signInWithApple();

  Future<Result<AuthSession>> updatePassword({required String password});

  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri);

  Future<Result<void>> signOut();
}
