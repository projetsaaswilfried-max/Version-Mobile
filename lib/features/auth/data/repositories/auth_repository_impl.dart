import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/auth_deep_link_result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  AuthSession _toSession(({String id, String email}) user) =>
      AuthSession(id: user.id, email: user.email);

  Failure _mapException(Object error) {
    return switch (error) {
      EmailNotConfirmedException(:final message) =>
        EmailNotConfirmedFailure(message),
      UnauthorizedException(:final message) => UnauthorizedFailure(message),
      NetworkException(:final message) => NetworkFailure(message),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      ServerException(:final message) => ServerFailure(message),
      _ => const UnknownFailure(),
    };
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (error) {
      return Err(_mapException(error));
    }
  }

  @override
  AuthSession? get currentSession {
    final user = _remote.currentUser;
    if (user == null) return null;
    return _toSession(user);
  }

  @override
  Stream<AuthSession?> get authStateChanges => _remote.onAuthStateChange.map(
    (user) => user == null ? null : _toSession(user),
  );

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) => _guard(
    () async => _toSession(
      await _remote.signInWithPassword(email: email, password: password),
    ),
  );

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) => _guard(
    () => _remote.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    ),
  );

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) => _guard(
    () async =>
        _toSession(await _remote.verifyEmailOtp(email: email, token: token)),
  );

  @override
  Future<Result<void>> resendSignupEmail({required String email}) =>
      _guard(() => _remote.resendSignupEmail(email: email));

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
      _guard(() => _remote.requestPasswordReset(email: email));

  @override
  Future<Result<void>> signInWithGoogle() => _guard(_remote.signInWithGoogle);

  @override
  Future<Result<AuthSession>> updatePassword({required String password}) =>
      _guard(
        () async =>
            _toSession(await _remote.updatePassword(password: password)),
      );

  @override
  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri) =>
      _guard(() => _remote.handleAuthDeepLink(uri));

  @override
  Future<Result<void>> signOut() => _guard(_remote.signOut);
}
