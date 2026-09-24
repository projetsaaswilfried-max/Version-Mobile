import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  bool signUpCalled = false;
  Result<void> signUpResult = const Ok(null);

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    signUpCalled = true;
    return signUpResult;
  }

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
  late ProviderContainer container;
  late _FakeAuthRepository repo;

  const validPassword = 'Abcdefg1';

  setUp(() {
    repo = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  RegistrationController controller() =>
      container.read(registrationControllerProvider.notifier);

  void fillValidFields(RegistrationController c) {
    c.setFirstName('Jean');
    c.setLastName('Dupont');
    c.setEmail('a@b.co');
    c.setPassword(validPassword);
    c.setPasswordConfirm(validPassword);
    c.setAcceptedTerms(true);
    c.setAcceptedCharter(true);
  }

  test('submit without CGU sets acceptedTerms error', () async {
    final c = controller();
    fillValidFields(c);
    c.setAcceptedTerms(false);

    await c.submit();

    expect(c.state.fieldErrors['acceptedTerms'], isNotNull);
    expect(c.state.succeeded, false);
    expect(c.state.isLoading, false);
    expect(repo.signUpCalled, isFalse);
  });

  test('submit with password mismatch sets passwordConfirm error', () async {
    final c = controller();
    fillValidFields(c);
    c.setPasswordConfirm('Abcdefg2');

    await c.submit();

    expect(c.state.fieldErrors['passwordConfirm'], isNotNull);
    expect(c.state.succeeded, false);
    expect(repo.signUpCalled, isFalse);
  });

  test('submit with valid data sets succeeded', () async {
    final c = controller();
    fillValidFields(c);

    await c.submit();

    expect(c.state.succeeded, isTrue);
    expect(c.state.isLoading, false);
    expect(c.state.formError, isNull);
    expect(c.state.fieldErrors, isEmpty);
    expect(repo.signUpCalled, isTrue);
  });

  test('submit maps repository failure to formError', () async {
    repo.signUpResult = const Err(ServerFailure('Compte déjà existant.'));
    final c = controller();
    fillValidFields(c);

    await c.submit();

    expect(c.state.formError, 'Compte déjà existant.');
    expect(c.state.succeeded, false);
    expect(c.state.isLoading, false);
  });
}
