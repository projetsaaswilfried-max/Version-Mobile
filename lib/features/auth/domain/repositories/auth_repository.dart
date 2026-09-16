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

  /// Launches the Google OAuth browser flow. Session arrives via deep link.
  Future<Result<void>> signInWithGoogle();

  Future<Result<AuthSession>> updatePassword({required String password});

  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri);

  Future<Result<void>> signOut();
}
