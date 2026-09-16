import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';

class SignInWithPassword {
  const SignInWithPassword(this._repo);

  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    final emailError = AuthValidators.email(email);
    final passwordError = AuthValidators.password(password);
    if (emailError != null || passwordError != null) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {
            if (emailError != null) 'email': emailError,
            if (passwordError != null) 'password': passwordError,
          },
        ),
      );
    }
    return _repo.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }
}
