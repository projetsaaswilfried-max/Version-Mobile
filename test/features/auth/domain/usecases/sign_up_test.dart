import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  bool signUpCalled = false;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    signUpCalled = true;
    return const Ok(null);
  }

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> resendSignupEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signOut() => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository repo;
  late SignUp useCase;

  setUp(() {
    repo = _FakeAuthRepository();
    useCase = SignUp(repo);
  });

  const validPassword = 'Abcdefg1';

  Future<Result<void>> validCall({
    bool acceptedTerms = true,
    bool acceptedCharter = true,
    String passwordConfirm = validPassword,
  }) =>
      useCase(
        email: 'a@b.co',
        password: validPassword,
        passwordConfirm: passwordConfirm,
        firstName: 'Jean',
        acceptedTerms: acceptedTerms,
        acceptedCharter: acceptedCharter,
      );

  test('rejects unchecked legal consent with acceptedTerms field error', () async {
    final result = await validCall(acceptedTerms: false);

    expect(result, isA<Err<void>>());
    final failure = (result as Err<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure as ValidationFailure).fieldErrors?['acceptedTerms'],
      isNotNull,
    );
    expect(repo.signUpCalled, isFalse);
  });

  test('rejects unchecked charter with acceptedTerms field error', () async {
    final result = await validCall(acceptedCharter: false);

    expect(result, isA<Err<void>>());
    final failure = (result as Err<void>).failure;
    expect(
      (failure as ValidationFailure).fieldErrors?['acceptedTerms'],
      isNotNull,
    );
    expect(repo.signUpCalled, isFalse);
  });

  test('rejects password mismatch on passwordConfirm', () async {
    final result = await validCall(passwordConfirm: 'Abcdefg2');

    expect(result, isA<Err<void>>());
    final failure = (result as Err<void>).failure;
    expect(
      (failure as ValidationFailure).fieldErrors?['passwordConfirm'],
      isNotNull,
    );
    expect(repo.signUpCalled, isFalse);
  });

  test('rejects empty firstName', () async {
    final result = await useCase(
      email: 'a@b.co',
      password: validPassword,
      passwordConfirm: validPassword,
      firstName: '   ',
      acceptedTerms: true,
      acceptedCharter: true,
    );

    expect(result, isA<Err<void>>());
    expect(
      ((result as Err<void>).failure as ValidationFailure)
          .fieldErrors?['firstName'],
      isNotNull,
    );
    expect(repo.signUpCalled, isFalse);
  });

  test('delegates to repository when valid', () async {
    final result = await validCall();

    expect(result, isA<Ok<void>>());
    expect(repo.signUpCalled, isTrue);
  });
}
