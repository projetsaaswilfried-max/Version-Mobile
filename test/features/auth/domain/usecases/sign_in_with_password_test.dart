import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  String? sentEmail;
  String? sentPassword;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    sentEmail = email;
    sentPassword = password;
    return Ok(AuthSession(id: 'u1', email: email));
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> resendSignupEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthSession>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> signInWithApple() => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> updatePassword({required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signOut() => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository repo;
  late SignInWithPassword usecase;

  setUp(() {
    repo = _FakeAuthRepository();
    usecase = SignInWithPassword(repo);
  });

  ValidationFailure asValidation(Result<AuthSession> result) =>
      (result as Err<AuthSession>).failure as ValidationFailure;

  test('rejects invalid email', () async {
    final result = await usecase(email: 'nope', password: 'Abcdefg1');

    expect(asValidation(result).fieldErrors?['email'], isNotNull);
    expect(repo.sentEmail, isNull);
  });

  test('rejects empty password', () async {
    final result = await usecase(email: 'a@b.co', password: '');

    expect(asValidation(result).fieldErrors?['password'], isNotNull);
    expect(repo.sentPassword, isNull);
  });

  test('accepts a weak legacy password (no strength rules on login)', () async {
    final result = await usecase(email: 'a@b.co', password: 'abc');

    expect(result, isA<Ok<AuthSession>>());
    expect(repo.sentPassword, 'abc');
  });

  test('trims the email before delegating', () async {
    await usecase(email: '  a@b.co  ', password: 'Abcdefg1');

    expect(repo.sentEmail, 'a@b.co');
  });
}
