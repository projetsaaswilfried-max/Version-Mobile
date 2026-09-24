import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repo);

  final AuthRepository _repo;

  Future<Result<AuthSession>> call() => _repo.signInWithGoogle();
}
