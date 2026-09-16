import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repo);

  final AuthRepository _repo;

  Future<Result<void>> call() => _repo.signInWithGoogle();
}
