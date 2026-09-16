import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  int verifyCalls = 0;
  int resendCalls = 0;
  Result<AuthSession> verifyResult = const Ok(
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
  }) async {
    verifyCalls++;
    return verifyResult;
  }

  @override
  Future<Result<void>> resendSignupEmail({required String email}) async {
    resendCalls++;
    return resendResult;
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
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
        otpControllerProvider.overrideWith(
          () => OtpController(clock: () => now),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  OtpController controller() => container.read(otpControllerProvider.notifier);

  test('submit with 5-digit code sets otp field error', () async {
    final c = controller();
    c.setOtp('12345');

    await c.submit(email: 'a@b.co');

    expect(c.state.fieldErrors['otp'], isNotNull);
    expect(c.state.succeeded, false);
    expect(c.state.isLoading, false);
    expect(repo.verifyCalls, 0);
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

  test('submit with valid otp sets succeeded', () async {
    final c = controller();
    c.setOtp('123456');

    await c.submit(email: 'a@b.co');

    expect(c.state.succeeded, isTrue);
    expect(c.state.isLoading, false);
    expect(c.state.formError, isNull);
    expect(repo.verifyCalls, 1);
  });

  test('submit maps repository failure to formError', () async {
    repo.verifyResult = const Err(
      ValidationFailure('Code incorrect ou expiré.'),
    );
    final c = controller();
    c.setOtp('123456');

    await c.submit(email: 'a@b.co');

    expect(c.state.formError, 'Code incorrect ou expiré.');
    expect(c.state.succeeded, false);
  });
}
