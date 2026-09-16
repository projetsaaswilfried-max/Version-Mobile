import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
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
  return AuthRepositoryImpl(
    SupabaseAuthDataSource(ref.watch(supabaseClientProvider)),
  );
});

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
