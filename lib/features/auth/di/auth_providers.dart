import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_deep_link_result.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/age_gate_store.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/resend_signup_email.dart';
import '../domain/usecases/sign_in_with_apple.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_in_with_password.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up.dart';
import '../domain/usecases/update_password.dart';
import '../domain/usecases/verify_email_otp.dart';

final ageGateStoreProvider = Provider<AgeGateStore>((ref) {
  throw UnimplementedError(
    'Override in ProviderScope after SharedPreferences.init',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredAuthRepository();
  }
  return AuthRepositoryImpl(
    SupabaseAuthDataSource(ref.watch(supabaseClientProvider)),
  );
});

/// Used when [main] skips [Supabase.initialize] (missing dart-defines).
///
/// Most methods return [Err] rather than throwing: a thrown exception here
/// would escape uncaught past the awaited usecase call in every auth
/// controller (none wrap the call in try/catch; data/repositories surface
/// failures through [Result]). That left `isLoading` stuck and the CTA
/// spinning forever.
///
/// Exception: [signUp] returns [Ok] so the local registration → profile
/// onboarding path still works without backend keys (#19).
class _UnconfiguredAuthRepository implements AuthRepository {
  const _UnconfiguredAuthRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async => const Err(_failure);

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async =>
      const Ok(null);

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Err(_failure);

  @override
  Future<Result<void>> resendSignupEmail({required String email}) async =>
      const Err(_failure);

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async =>
      const Err(_failure);

  @override
  Future<Result<AuthSession>> signInWithGoogle() async => const Err(_failure);

  @override
  Future<Result<AuthSession>> signInWithApple() async => const Err(_failure);

  @override
  Future<Result<AuthSession>> updatePassword({
    required String password,
  }) async => const Err(_failure);

  @override
  Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri) async =>
      const Err(_failure);

  @override
  Future<Result<void>> signOut() async => const Err(_failure);
}

final signInWithPasswordProvider = Provider(
  (ref) => SignInWithPassword(ref.watch(authRepositoryProvider)),
);

final signUpProvider = Provider(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

final verifyEmailOtpProvider = Provider(
  (ref) => VerifyEmailOtp(ref.watch(authRepositoryProvider)),
);

final resendSignupEmailProvider = Provider(
  (ref) => ResendSignupEmail(ref.watch(authRepositoryProvider)),
);

final requestPasswordResetProvider = Provider(
  (ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleProvider = Provider(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signInWithAppleProvider = Provider(
  (ref) => SignInWithApple(ref.watch(authRepositoryProvider)),
);

final updatePasswordProvider = Provider(
  (ref) => UpdatePassword(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);
