import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/verify_email/verify_email_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  int signInCalls = 0;
  int resendCalls = 0;
  Result<AuthSession> signInResult = const Ok(
    AuthSession(id: '1', email: 'a@b.co'),
  );
  Result<void> resendResult = const Ok(null);

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
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
  Future<Result<void>> resendSignupEmail({required String email}) async {
    resendCalls++;
    return resendResult;
  }

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
  late DateTime now;

  setUp(() {
    repo = _FakeAuthRepository();
    now = DateTime(2026, 9, 16, 12);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        verifyEmailControllerProvider.overrideWith(
          () => VerifyEmailController(clock: () => now),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  VerifyEmailController controller() =>
      container.read(verifyEmailControllerProvider.notifier);

  test('confirm calls signIn and sets succeeded', () async {
    final c = controller();

    await c.confirm(email: 'a@b.co', password: 'Abcdefg1');

    expect(repo.signInCalls, 1);
    expect(c.state.succeeded, isTrue);
    expect(c.state.isLoading, false);
    expect(c.state.formError, isNull);
  });

  test('confirm maps email_not_confirmed to formError', () async {
    repo.signInResult = const Err(
      UnauthorizedFailure(
        'Email non confirmé. Vérifie ta boîte mail ou saisis le code.',
      ),
    );
    final c = controller();

    await c.confirm(email: 'a@b.co', password: 'Abcdefg1');

    expect(repo.signInCalls, 1);
    expect(c.state.formError, isNotNull);
    expect(c.state.succeeded, false);
    expect(c.state.isLoading, false);
  });

  test('resend starts 60s cooldown and second resend is a no-op', () async {
    final c = controller();

    await c.resend(email: 'a@b.co');

    expect(repo.resendCalls, 1);
    expect(c.state.resendAllowedAt, now.add(const Duration(seconds: 60)));

    await c.resend(email: 'a@b.co');

    expect(repo.resendCalls, 1);
    expect(c.state.resendAllowedAt, now.add(const Duration(seconds: 60)));
  });
}
