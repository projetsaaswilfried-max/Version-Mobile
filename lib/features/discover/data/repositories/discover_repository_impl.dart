import '../../../../core/error/exceptions.dart';
import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/discover_candidates_page.dart';
import '../../domain/entities/discover_profile_detail.dart';
import '../../domain/entities/visitor_context.dart';
import '../../domain/repositories/discover_repository.dart';
import '../../domain/scoring/compatibility_traits.dart';
import '../datasources/discover_remote_datasource.dart';
import '../models/discover_profile_detail_model.dart';
import '../models/discover_profile_model.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._remote, {this.clock});

  final DiscoverRemoteDataSource _remote;
  final DateTime Function()? clock;

  @override
  Future<Result<VisitorContext>> fetchVisitor() async {
    try {
      final raw = await _remote.fetchVisitorRaw();
      final visitor = DiscoverProfileModel.visitorFromJson(
        profile: raw.profile,
        subscriptionStatus: raw.subscriptionStatus,
        now: clock,
      );
      if (visitor == null) {
        throw const ServerException('Profil introuvable.');
      }
      return Ok(visitor);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<DiscoverCandidatesPage>> fetchCandidates({
    required int offset,
    required int limit,
    String? search,
  }) async {
    try {
      final rows = await _remote.fetchCandidateRows(
        offset: offset,
        limit: limit,
        search: search,
      );
      final profiles = [
        for (final row in rows)
          if (DiscoverProfileModel.fromJson(
                row,
                visitorTraits: const CompatibilityTraits(),
                revealIdentity: true,
                now: clock,
              )
              case final profile?)
            profile,
      ];
      return Ok(
        DiscoverCandidatesPage(profiles: profiles, hasMore: rows.length >= limit),
      );
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<Set<String>>> fetchLikedProfileIds() async {
    try {
      return Ok(await _remote.fetchLikedProfileIds());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<Set<String>>> fetchFavoritedProfileIds() async {
    try {
      return Ok(await _remote.fetchFavoritedProfileIds());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<DiscoverProfileDetail>> fetchProfileDetail(
    String profileId,
  ) async {
    try {
      final row = await _remote.fetchProfileDetailRow(profileId);
      final detail = DiscoverProfileDetailModel.fromJson(row, now: clock);
      if (detail == null) {
        throw const ServerException('Profil introuvable.');
      }
      return Ok(detail);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> recordProfileView(String viewedProfileId) async {
    try {
      await _remote.recordProfileView(viewedProfileId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<bool>> isProfileLiked(String profileId) async {
    try {
      return Ok(await _remote.isProfileLiked(profileId));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> likeProfile(String profileId) async {
    try {
      await _remote.likeProfile(profileId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> unlikeProfile(String profileId) async {
    try {
      await _remote.unlikeProfile(profileId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<bool>> isProfileFavorited(String profileId) async {
    try {
      return Ok(await _remote.isProfileFavorited(profileId));
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> favoriteProfile(String profileId) async {
    try {
      await _remote.favoriteProfile(profileId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> unfavoriteProfile(String profileId) async {
    try {
      await _remote.unfavoriteProfile(profileId);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<int>> countMonthlyInvitations() async {
    try {
      return Ok(await _remote.countMonthlyInvitations());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }

  @override
  Future<Result<void>> sendInvitation({
    required String profileId,
    String? message,
  }) async {
    try {
      await _remote.sendInvitation(profileId: profileId, message: message);
      return const Ok(null);
    } catch (error) {
      return Err(mapDataException(error));
    }
  }
}
