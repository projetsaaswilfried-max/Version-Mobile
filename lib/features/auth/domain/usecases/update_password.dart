import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';

class UpdatePassword {
  const UpdatePassword(this._repo);

  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String password,
    required String passwordConfirm,
  }) async {
    final passwordError = AuthValidators.password(password);
    if (passwordError != null) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {'password': passwordError},
        ),
      );
    }
    if (password != passwordConfirm) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {
            'passwordConfirm': 'Les mots de passe ne correspondent pas.',
          },
        ),
      );
    }
    return _repo.updatePassword(password: password);
  }
}
