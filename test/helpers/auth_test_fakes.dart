import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/age_gate_store.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/onboarding/domain/repositories/intro_store.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentSession});

  @override
  AuthSession? currentSession;

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
  Future<Result<void>> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> signOut() async => const Ok(null);
}

class FakeAgeGateStore implements AgeGateStore {
  FakeAgeGateStore({bool accepted = false}) : _accepted = accepted;

  bool _accepted;

  @override
  Future<bool> isAccepted() async => _accepted;

  @override
  Future<void> accept() async {
    _accepted = true;
  }
}

class FakeIntroStore implements IntroStore {
  FakeIntroStore({bool seen = false}) : _seen = seen;

  bool _seen;

  @override
  Future<bool> isSeen() async => _seen;

  @override
  Future<void> markSeen() async {
    _seen = true;
  }
}
