import '../../../../core/error/result.dart';
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

  Future<Result<void>> signOut();
}
