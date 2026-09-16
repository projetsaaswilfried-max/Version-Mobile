import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/age_gate_store.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/resend_signup_email.dart';
import '../domain/usecases/sign_in_with_password.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up.dart';
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
class _UnconfiguredAuthRepository implements AuthRepository {
  const _UnconfiguredAuthRepository();

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) =>
      throw StateError('Supabase is not configured');

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) =>
      throw StateError('Supabase is not configured');

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  }) =>
      throw StateError('Supabase is not configured');

  @override
  Future<Result<void>> resendSignupEmail({required String email}) =>
      throw StateError('Supabase is not configured');

  @override
  Future<Result<void>> requestPasswordReset({required String email}) =>
      throw StateError('Supabase is not configured');

  @override
  Future<Result<void>> signOut() => throw StateError('Supabase is not configured');
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

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);
