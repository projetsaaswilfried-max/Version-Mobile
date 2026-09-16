import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._repo);

  final AuthRepository _repo;

  Future<Result<void>> call() => _repo.signOut();
}
