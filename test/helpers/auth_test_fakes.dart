import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/repositories/age_gate_store.dart';
import 'package:agapeo/features/auth/domain/repositories/auth_repository.dart';
import 'package:agapeo/features/onboarding/domain/repositories/intro_store.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.currentSession,
    this.signInWithGoogleResult = const Ok(null),
    this.updatePasswordResult,
  });

  @override
  AuthSession? currentSession;

  bool signInWithGoogleCalled = false;
  bool updatePasswordCalled = false;

  final Result<void> signInWithGoogleResult;
  final Result<AuthSession>? updatePasswordResult;

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
  Future<Result<void>> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    return signInWithGoogleResult;
  }

  @override
  Future<Result<AuthSession>> updatePassword({required String password}) async {
    updatePasswordCalled = true;
    return updatePasswordResult ??
        Ok(currentSession ?? const AuthSession(id: '1', email: 'a@b.co'));
  }

  @override
  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri) async =>
      const Ok(AuthDeepLinkIgnored());

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
