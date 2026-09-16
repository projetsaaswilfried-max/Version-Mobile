import 'package:agapeo/core/config/app_environment.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/login/login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  bool signInCalled = false;
  Result<AuthSession> signInResult = const Ok(
    AuthSession(id: '1', email: 'a@b.co'),
  );

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    return signInResult;
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
  Future<Result<void>> signInWithGoogle() =>
      throw UnimplementedError();

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

  setUp(() {
    repo = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);

  test('submit with empty email sets field error', () async {
    final c = controller();

    await c.submit();

    expect(c.state.fieldErrors['email'], isNotNull);
    expect(c.state.isLoading, false);
    expect(c.state.succeeded, false);
    expect(repo.signInCalled, isFalse);
  });

  test('submit with valid credentials sets succeeded', () async {
    final c = controller();
    c.setEmail('a@b.co');
    c.setPassword('Abcdefg1');

    await c.submit();

    expect(c.state.succeeded, isTrue);
    expect(c.state.isLoading, false);
    expect(c.state.formError, isNull);
    expect(c.state.fieldErrors, isEmpty);
    expect(repo.signInCalled, isTrue);
  });

  test('submit maps repository failure to formError', () async {
    repo.signInResult = const Err(
      UnauthorizedFailure('Identifiants incorrects.'),
    );
    final c = controller();
    c.setEmail('a@b.co');
    c.setPassword('Abcdefg1');

    await c.submit();

    expect(c.state.formError, 'Identifiants incorrects.');
    expect(c.state.succeeded, false);
    expect(c.state.isLoading, false);
  });

  test('setEmail clears email field error', () async {
    final c = controller();
    await c.submit();
    expect(c.state.fieldErrors['email'], isNotNull);

    c.setEmail('a@b.co');

    expect(c.state.fieldErrors['email'], isNull);
  });

  test(
    'submit without a configured Supabase repo resets isLoading and sets formError '
    '(regression: _UnconfiguredAuthRepository used to throw uncaught, leaving the CTA spinning forever)',
    () async {
      try {
        AppEnvironment.init();
      } catch (_) {
        // Already initialized by another test in this VM.
      }
      final unconfiguredContainer = ProviderContainer();
      addTearDown(unconfiguredContainer.dispose);
      final c = unconfiguredContainer.read(loginControllerProvider.notifier);
      c.setEmail('a@b.co');
      c.setPassword('Abcdefg1');

      await c.submit();

      expect(c.state.isLoading, false);
      expect(c.state.succeeded, false);
      expect(c.state.formError, isNotNull);
    },
  );

  test(
    'submit maps EmailNotConfirmedFailure to emailNotConfirmed flag',
    () async {
      repo.signInResult = const Err(
        EmailNotConfirmedFailure('Email non confirmé.'),
      );
      final c = controller();
      c.setEmail('a@b.co');
      c.setPassword('Abcdefg1');

      await c.submit();

      expect(c.state.emailNotConfirmed, isTrue);
      expect(c.state.formError, 'Email non confirmé.');
      expect(c.state.succeeded, false);
    },
  );

  test('a later non-confirmation failure clears emailNotConfirmed', () async {
    repo.signInResult = const Err(EmailNotConfirmedFailure());
    final c = controller();
    c.setEmail('a@b.co');
    c.setPassword('Abcdefg1');
    await c.submit();
    expect(c.state.emailNotConfirmed, isTrue);

    repo.signInResult = const Err(UnauthorizedFailure('Mot de passe incorrect.'));
    await c.submit();

    expect(c.state.emailNotConfirmed, isFalse);
  });
}
