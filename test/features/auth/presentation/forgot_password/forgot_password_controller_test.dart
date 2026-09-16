import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _genericSuccess =
    'Si un compte existe pour cette adresse, tu recevras un email avec la suite.';

class _FakeAuthRepository implements AuthRepository {
  bool resetCalled = false;
  String? resetEmail;
  Result<void> resetResult = const Ok(null);

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
  Future<Result<void>> requestPasswordReset({required String email}) async {
    resetCalled = true;
    resetEmail = email;
    return resetResult;
  }

  @override
  Future<Result<void>> signOut() => throw UnimplementedError();
}

void main() {
  late ProviderContainer container;
  late _FakeAuthRepository repo;

  setUp(() {
    repo = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  ForgotPasswordController controller() =>
      container.read(forgotPasswordControllerProvider.notifier);

  test('submit with empty email sets field error', () async {
    final c = controller();

    await c.submit();

    expect(c.state.fieldErrors['email'], isNotNull);
    expect(c.state.isLoading, false);
    expect(c.state.successMessage, isNull);
    expect(repo.resetCalled, isFalse);
  });

  test('submit on success sets generic successMessage', () async {
    final c = controller();
    c.setEmail('unknown@example.com');

    await c.submit();

    expect(c.state.successMessage, _genericSuccess);
    expect(c.state.formError, isNull);
    expect(c.state.fieldErrors, isEmpty);
    expect(c.state.isLoading, false);
    expect(repo.resetCalled, isTrue);
    expect(repo.resetEmail, 'unknown@example.com');
  });

  test('submit on server failure still sets generic successMessage', () async {
    repo.resetResult = const Err(
      ServerFailure('Cette adresse email est introuvable.'),
    );
    final c = controller();
    c.setEmail('nobody@example.com');

    await c.submit();

    expect(c.state.successMessage, _genericSuccess);
    expect(c.state.formError, isNull);
    expect(c.state.successMessage, isNot(contains('introuvable')));
  });

  test('submit on network failure sets formError', () async {
    repo.resetResult = const Err(NetworkFailure());
    final c = controller();
    c.setEmail('a@b.co');

    await c.submit();

    expect(c.state.formError, 'Pas de connexion internet.');
    expect(c.state.successMessage, isNull);
    expect(c.state.isLoading, false);
  });

  test('setEmail clears email field error', () async {
    final c = controller();
    await c.submit();
    expect(c.state.fieldErrors['email'], isNotNull);

    c.setEmail('a@b.co');

    expect(c.state.fieldErrors['email'], isNull);
  });
}
