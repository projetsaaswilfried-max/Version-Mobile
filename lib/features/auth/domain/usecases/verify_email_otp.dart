import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';

class VerifyEmailOtp {
  const VerifyEmailOtp(this._repo);

  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String email,
    required String token,
  }) async {
    final emailError = AuthValidators.email(email);
    final otpError = AuthValidators.otp(token);
    if (emailError != null || otpError != null) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {
            if (emailError != null) 'email': emailError,
            if (otpError != null) 'otp': otpError,
          },
        ),
      );
    }
    return _repo.verifyEmailOtp(
      email: email.trim(),
      token: token.trim(),
    );
  }
}
