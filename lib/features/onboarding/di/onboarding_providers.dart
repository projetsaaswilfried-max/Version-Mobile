import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_onboarding_datasource.dart';
import '../data/repositories/onboarding_repository_impl.dart';
import '../domain/entities/onboarding_submit_payload.dart';
import '../domain/repositories/intro_store.dart';
import '../domain/repositories/onboarding_repository.dart';
import '../domain/usecases/finish_without_verification.dart';
import '../domain/usecases/submit_onboarding.dart';

final introStoreProvider = Provider<IntroStore>((ref) {
  throw UnimplementedError(
    'Override in ProviderScope after SharedPreferences.init',
  );
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredOnboardingRepository();
  }
  return OnboardingRepositoryImpl(
    SupabaseOnboardingDataSource(ref.watch(supabaseClientProvider)),
  );
});

final submitOnboardingProvider = Provider(
  (ref) => SubmitOnboarding(ref.watch(onboardingRepositoryProvider)),
);

final finishWithoutVerificationProvider = Provider(
  (ref) =>
      FinishWithoutVerification(ref.watch(onboardingRepositoryProvider)),
);

class _UnconfiguredOnboardingRepository implements OnboardingRepository {
  const _UnconfiguredOnboardingRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<void>> submit(OnboardingSubmitPayload payload) async =>
      const Err(_failure);

  @override
  Future<Result<void>> finishWithoutVerification(
    OnboardingSubmitPayload payload,
  ) async =>
      const Err(_failure);
}
