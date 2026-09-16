import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';

class ResendSignupEmail {
  const ResendSignupEmail(this._repo);

  final AuthRepository _repo;

  Future<Result<void>> call({required String email}) async {
    final emailError = AuthValidators.email(email);
    if (emailError != null) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {'email': emailError},
        ),
      );
    }
    return _repo.resendSignupEmail(email: email.trim());
  }
}
