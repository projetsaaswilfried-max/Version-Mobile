import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_discover_datasource.dart';
import '../data/repositories/discover_repository_impl.dart';
import '../domain/entities/discover_candidates_page.dart';
import '../domain/entities/discover_profile_detail.dart';
import '../domain/entities/discover_query.dart';
import '../domain/entities/visitor_context.dart';
import '../domain/repositories/discover_repository.dart';
import '../domain/usecases/favorite_discover_profile.dart';
import '../domain/usecases/get_discover_page.dart';
import '../domain/usecases/get_discover_profile_detail.dart';
import '../domain/usecases/is_discover_profile_favorited.dart';
import '../domain/usecases/is_discover_profile_liked.dart';
import '../domain/usecases/like_discover_profile.dart';
import '../domain/usecases/record_discover_profile_view.dart';
import '../domain/usecases/send_discover_invitation.dart';
import '../domain/usecases/unfavorite_discover_profile.dart';
import '../domain/usecases/unlike_discover_profile.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const UnconfiguredDiscoverRepository();
  }
  return DiscoverRepositoryImpl(
    SupabaseDiscoverDataSource(ref.watch(supabaseClientProvider)),
  );
});

final getDiscoverPageProvider = Provider(
  (ref) => GetDiscoverPage(ref.watch(discoverRepositoryProvider)),
);

final getDiscoverProfileDetailProvider = Provider(
  (ref) => GetDiscoverProfileDetail(ref.watch(discoverRepositoryProvider)),
);

final recordDiscoverProfileViewProvider = Provider(
  (ref) => RecordDiscoverProfileView(ref.watch(discoverRepositoryProvider)),
);

final likeDiscoverProfileProvider = Provider(
  (ref) => LikeDiscoverProfile(ref.watch(discoverRepositoryProvider)),
);

final unlikeDiscoverProfileProvider = Provider(
  (ref) => UnlikeDiscoverProfile(ref.watch(discoverRepositoryProvider)),
);

final isDiscoverProfileLikedProvider = Provider(
  (ref) => IsDiscoverProfileLiked(ref.watch(discoverRepositoryProvider)),
);

final favoriteDiscoverProfileProvider = Provider(
  (ref) => FavoriteDiscoverProfile(ref.watch(discoverRepositoryProvider)),
);

final unfavoriteDiscoverProfileProvider = Provider(
  (ref) => UnfavoriteDiscoverProfile(ref.watch(discoverRepositoryProvider)),
);

final isDiscoverProfileFavoritedProvider = Provider(
  (ref) => IsDiscoverProfileFavorited(ref.watch(discoverRepositoryProvider)),
);

final sendDiscoverInvitationProvider = Provider(
  (ref) => SendDiscoverInvitation(ref.watch(discoverRepositoryProvider)),
);

class UnconfiguredDiscoverRepository implements DiscoverRepository {
  const UnconfiguredDiscoverRepository();

  static const failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<VisitorContext>> fetchVisitor() async => const Err(failure);

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    DiscoverQuery query = const DiscoverQuery(),
  }) async => const Err(failure);

  @override
  Future<Result<Set<String>>> fetchLikedProfileIds() async =>
      const Err(failure);

  @override
  Future<Result<Set<String>>> fetchFavoritedProfileIds() async =>
      const Err(failure);

  @override
  Future<Result<DiscoverProfileDetail>> fetchProfileDetail(
    String profileId,
  ) async => const Err(failure);

  @override
  Future<Result<void>> recordProfileView(String viewedProfileId) async =>
      const Err(failure);

  @override
  Future<Result<bool>> isProfileLiked(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<void>> likeProfile(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<void>> unlikeProfile(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<bool>> isProfileFavorited(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<void>> favoriteProfile(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async =>
      const Err(failure);

  @override
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async => const Err(failure);
}
