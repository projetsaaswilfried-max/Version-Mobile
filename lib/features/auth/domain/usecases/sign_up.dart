import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';

class SignUp {
  const SignUp(this._repo);

  final AuthRepository _repo;

  Future<Result<void>> call({
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    String? lastName,
    required bool acceptedTerms,
    required bool acceptedCharter,
  }) async {
    final emailError = AuthValidators.email(email);
    final passwordError = AuthValidators.password(password);
    final firstNameError = firstName.trim().isEmpty
        ? 'Le prénom est requis.'
        : null;
    final passwordConfirmError = password != passwordConfirm
        ? 'Les mots de passe ne correspondent pas.'
        : null;
    final legalError = (!acceptedTerms || !acceptedCharter)
        ? 'Tu dois accepter les conditions générales d\'utilisation et la charte d\'éthique.'
        : null;

    final fieldErrors = {
      if (emailError != null) 'email': emailError,
      if (passwordError != null) 'password': passwordError,
      if (firstNameError != null) 'firstName': firstNameError,
      if (passwordConfirmError != null) 'passwordConfirm': passwordConfirmError,
      if (legalError != null) 'acceptedTerms': legalError,
    };

    if (fieldErrors.isNotEmpty) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final trimmedLastName = lastName?.trim();
    return _repo.signUp(
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName:
          trimmedLastName == null || trimmedLastName.isEmpty
              ? null
              : trimmedLastName,
    );
  }
}
