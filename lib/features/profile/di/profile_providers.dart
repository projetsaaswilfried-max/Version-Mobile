import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_my_profile_datasource.dart';
import '../data/datasources/supabase_profile_account_datasource.dart';
import '../data/datasources/supabase_profile_fields_datasource.dart';
import '../data/datasources/supabase_profile_gate_datasource.dart';
import '../data/repositories/my_profile_repository_impl.dart';
import '../data/repositories/profile_account_repository_impl.dart';
import '../data/repositories/profile_fields_repository_impl.dart';
import '../data/repositories/profile_gate_repository_impl.dart';
import '../domain/entities/account_person.dart';
import '../domain/entities/faith_details.dart';
import '../domain/entities/more_info_details.dart';
import '../domain/entities/my_profile.dart';
import '../domain/entities/member_gate_snapshot.dart';
import '../domain/entities/privacy_settings.dart';
import '../domain/entities/profile_completeness.dart';
import '../domain/entities/profile_fields_snapshot.dart';
import '../domain/entities/public_profile_preview.dart';
import '../domain/entities/verification_info.dart';
import '../domain/repositories/my_profile_repository.dart';
import '../domain/repositories/profile_account_repository.dart';
import '../domain/repositories/profile_fields_repository.dart';
import '../domain/repositories/profile_gate_repository.dart';
import '../domain/usecases/compute_profile_completeness.dart';
import '../domain/usecases/get_my_profile.dart';
import '../domain/usecases/get_profile_hub.dart';
import '../domain/usecases/resolve_post_login_route.dart';
import '../domain/usecases/save_faith_details.dart';
import '../domain/usecases/save_more_info_details.dart';
import '../domain/usecases/save_my_profile.dart';

final profileGateRepositoryProvider = Provider<ProfileGateRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredProfileGateRepository();
  }
  return ProfileGateRepositoryImpl(
    SupabaseProfileGateDataSource(ref.watch(supabaseClientProvider)),
  );
});

final resolvePostLoginRouteProvider = Provider(
  (_) => const ResolvePostLoginRoute(),
);

final profileFieldsRepositoryProvider = Provider<ProfileFieldsRepository>((
  ref,
) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredProfileFieldsRepository();
  }
  return ProfileFieldsRepositoryImpl(
    SupabaseProfileFieldsDataSource(ref.watch(supabaseClientProvider)),
  );
});

final computeProfileCompletenessProvider = Provider(
  (_) => const ComputeProfileCompleteness(),
);

final getProfileHubProvider = Provider<GetProfileHub>((ref) {
  return GetProfileHub(ref.watch(profileFieldsRepositoryProvider));
});

final myProfileRepositoryProvider = Provider<MyProfileRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredMyProfileRepository();
  }
  return MyProfileRepositoryImpl(
    SupabaseMyProfileDataSource(ref.watch(supabaseClientProvider)),
  );
});

final getMyProfileProvider = Provider<GetMyProfile>((ref) {
  return GetMyProfile(ref.watch(myProfileRepositoryProvider));
});

final saveMyProfileProvider = Provider<SaveMyProfile>((ref) {
  return SaveMyProfile(ref.watch(myProfileRepositoryProvider));
});

final profileAccountRepositoryProvider = Provider<ProfileAccountRepository>((
  ref,
) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredProfileAccountRepository();
  }
  return ProfileAccountRepositoryImpl(
    SupabaseProfileAccountDataSource(ref.watch(supabaseClientProvider)),
  );
});

final saveFaithDetailsProvider = Provider<SaveFaithDetails>((ref) {
  return SaveFaithDetails(ref.watch(profileAccountRepositoryProvider));
});

final saveMoreInfoDetailsProvider = Provider<SaveMoreInfoDetails>((ref) {
  return SaveMoreInfoDetails(ref.watch(profileAccountRepositoryProvider));
});

/// Cache session-wide des champs profil (pas autoDispose) : hydrate
/// onboarding, Découvrir (gate / bannières) et prefetch post-login.
final profileFieldsProvider = FutureProvider<Result<ProfileFieldsSnapshot>>((
  ref,
) {
  return ref.watch(profileFieldsRepositoryProvider).fetchFields();
});

/// Async complétude profil (Découvrir). Err → traité comme inconnu (soft).
final profileCompletenessProvider =
    FutureProvider.autoDispose<ProfileCompleteness?>((ref) async {
      final result = await ref.watch(profileFieldsProvider.future);
      return switch (result) {
        Ok(:final value) => ref.read(computeProfileCompletenessProvider)(value),
        Err() => null,
      };
    });

final memberGateProvider = FutureProvider<Result<MemberGateSnapshot>>((ref) {
  return ref.watch(profileGateRepositoryProvider).fetchGate();
});

/// Used when [main] skips [Supabase.initialize] (missing dart-defines).
///
/// Returns [Err] rather than throwing: a thrown exception here would escape
/// uncaught past callers that only handle [Result].
class _UnconfiguredProfileGateRepository implements ProfileGateRepository {
  const _UnconfiguredProfileGateRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<MemberGateSnapshot>> fetchGate() async => const Err(_failure);
}

class _UnconfiguredMyProfileRepository implements MyProfileRepository {
  const _UnconfiguredMyProfileRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<MyProfile>> fetchMine() async => const Err(_failure);

  @override
  Future<Result<void>> save(
    MyProfile profile, {
    required bool savePhotos,
  }) async => const Err(_failure);

  @override
  Future<Result<void>> deletePhoto(String photoId) async => const Err(_failure);
}

class _UnconfiguredProfileFieldsRepository implements ProfileFieldsRepository {
  const _UnconfiguredProfileFieldsRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async =>
      const Err(_failure);
}

class _UnconfiguredProfileAccountRepository
    implements ProfileAccountRepository {
  const _UnconfiguredProfileAccountRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<FaithDetails>> fetchFaith() async => const Err(_failure);

  @override
  Future<Result<void>> saveFaith(FaithDetails details) async =>
      const Err(_failure);

  @override
  Future<Result<MoreInfoDetails>> fetchMoreInfo() async => const Err(_failure);

  @override
  Future<Result<void>> saveMoreInfo(MoreInfoDetails details) async =>
      const Err(_failure);

  @override
  Future<Result<PrivacySettings>> fetchPrivacy() async => const Err(_failure);

  @override
  Future<Result<void>> savePrivacy(PrivacySettings settings) async =>
      const Err(_failure);

  @override
  Future<Result<List<AccountPerson>>> fetchFavorites() async =>
      const Err(_failure);

  @override
  Future<Result<void>> removeFavorite(String profileId) async =>
      const Err(_failure);

  @override
  Future<Result<InterestedPeople>> fetchInterested() async =>
      const Err(_failure);

  @override
  Future<Result<List<AccountPerson>>> fetchBlocked() async =>
      const Err(_failure);

  @override
  Future<Result<void>> unblock(String profileId) async => const Err(_failure);

  @override
  Future<Result<VerificationInfo>> fetchVerification() async =>
      const Err(_failure);

  @override
  Future<Result<void>> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  }) async => const Err(_failure);

  @override
  Future<Result<void>> changeEmail(String email) async => const Err(_failure);

  @override
  Future<Result<String>> exportJson() async => const Err(_failure);

  @override
  Future<Result<void>> deleteAccount() async => const Err(_failure);

  @override
  Future<Result<PublicProfilePreview>> fetchPublicPreview() async =>
      const Err(_failure);

  @override
  Future<Result<void>> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  }) async => const Err(_failure);
}
