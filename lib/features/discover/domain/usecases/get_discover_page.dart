import '../../../../core/error/result.dart';
import '../daily/daily_recommended.dart';
import '../eligibility/discover_eligibility.dart';
import '../entities/discover_page.dart';
import '../entities/discover_profile.dart';
import '../entities/discover_query.dart';
import '../entities/visitor_context.dart';
import '../masking/discover_mask.dart';
import '../repositories/discover_repository.dart';
import '../scoring/compatibility_score.dart';

class GetDiscoverPage {
  const GetDiscoverPage(this._repo, {this.clock});

  /// Nombre de lignes brutes demandées au serveur par page. Le "recommandé"
  /// du jour n'est calculé qu'une fois, sur la toute première page — les
  /// pages suivantes (`loadMore`) alimentent uniquement "autres profils".
  static const serverBatchSize = 60;

  final DiscoverRepository _repo;
  final DateTime Function()? clock;

  Future<Result<DiscoverPage>> call() async {
    final visitorResult = await _repo.fetchVisitor();
    switch (visitorResult) {
      case Err<VisitorContext>(:final failure):
        return Err(failure);
      case Ok<VisitorContext>(:final value):
        // EXPIRED se comporte comme FREE ici (D42) - toujours des candidats,
        // pas de page vide.
        return _pageForVisitor(value);
    }
  }

  /// Page suivante de "autres profils", pour `loadMore`. Ne recalcule pas
  /// le "recommandé" du jour (déjà figé par [call]).
  Future<Result<DiscoverMorePage>> more({
    required VisitorContext visitor,
    required int offset,
    DiscoverQuery query = const DiscoverQuery(),
  }) async {
    final candidatesFuture = _repo.fetchCandidates(
      offset: offset,
      limit: serverBatchSize,
      query: query,
    );
    final likedFuture = _repo.fetchLikedProfileIds();
    final favoritedFuture = _repo.fetchFavoritedProfileIds();

    final candidatesResult = await candidatesFuture;
    switch (candidatesResult) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final likedIds = await _resolveIds(likedFuture);
        final favoritedIds = await _resolveIds(favoritedFuture);
        final eligible = _eligibleScored(
          visitor,
          value.profiles,
          likedIds,
          favoritedIds,
        );
        final reveal = revealCardIdentity(visitorVerified: visitor.isVerified);
        return Ok(
          DiscoverMorePage(
            others: eligible.map((p) => _present(p, reveal)).toList(),
            hasMore: value.hasMore,
          ),
        );
    }
  }

  Future<Result<DiscoverPage>> _pageForVisitor(VisitorContext visitor) async {
    final candidatesFuture = _repo.fetchCandidates(
      offset: 0,
      limit: serverBatchSize,
    );
    final likedFuture = _repo.fetchLikedProfileIds();
    final favoritedFuture = _repo.fetchFavoritedProfileIds();

    final candidatesResult = await candidatesFuture;
    switch (candidatesResult) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final likedIds = await _resolveIds(likedFuture);
        final favoritedIds = await _resolveIds(favoritedFuture);
        return Ok(
          _assemble(visitor, value.profiles, likedIds, favoritedIds, value.hasMore),
        );
    }
  }

  Future<Set<String>> _resolveIds(Future<Result<Set<String>>> future) async {
    return switch (await future) {
      Ok<Set<String>>(value: final ids) => ids,
      Err<Set<String>>() => const <String>{},
    };
  }

  List<DiscoverProfile> _eligibleScored(
    VisitorContext visitor,
    List<DiscoverProfile> candidates,
    Set<String> likedIds,
    Set<String> favoritedIds,
  ) {
    final visitorGender = visitor.gender;
    final eligible = <DiscoverProfile>[];
    if (visitorGender == null) return eligible;
    for (final candidate in candidates) {
      if (candidate.id == visitor.id) continue;
      if (!isDiscoverEligible(
        visitorGender: visitorGender,
        candidate: CandidateEligibility(
          id: candidate.id,
          gender: candidate.gender,
          isStaff: candidate.isStaff,
          isVerified: candidate.isVerified,
          isMatched: candidate.isMatched,
          isComplete: candidate.isComplete,
        ),
      )) {
        continue;
      }
      eligible.add(
        candidate.copyWith(
          score: compatibilityScore(
            visitor: visitor.traits,
            candidate: candidate.traits,
          ),
          isLiked: likedIds.contains(candidate.id),
          isFavorited: favoritedIds.contains(candidate.id),
        ),
      );
    }
    eligible.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return a.id.compareTo(b.id);
    });
    return eligible;
  }

  DiscoverPage _assemble(
    VisitorContext visitor,
    List<DiscoverProfile> candidates,
    Set<String> likedIds,
    Set<String> favoritedIds,
    bool hasMoreCandidates,
  ) {
    final eligible = _eligibleScored(visitor, candidates, likedIds, favoritedIds);

    final utcDay = (clock ?? DateTime.now)().toUtc();
    final recommended = pickDailyRecommended(
      ranked: eligible,
      visitorId: visitor.id,
      utcDay: utcDay,
      idOf: (profile) => profile.id,
      scoreOf: (profile) => profile.score,
    );
    final recommendedIds = recommended.map((profile) => profile.id).toSet();
    final others = eligible
        .where((profile) => !recommendedIds.contains(profile.id))
        .toList();

    final reveal = revealCardIdentity(visitorVerified: visitor.isVerified);

    return DiscoverPage(
      recommended: recommended.map((p) => _present(p, reveal)).toList(),
      others: others.map((p) => _present(p, reveal)).toList(),
      visitor: visitor,
      hasMoreCandidates: hasMoreCandidates,
    );
  }

  DiscoverProfile _present(DiscoverProfile profile, bool reveal) {
    if (reveal) {
      return profile.copyWith(
        ageLabel: profile.age?.toString(),
        clearAgeLabel: profile.age == null,
      );
    }
    return profile.copyWith(
      displayName: maskIdentity(profile.displayName),
      city: profile.city == null ? null : maskIdentity(profile.city!),
      clearCity: profile.city == null,
      clearAge: true,
      ageLabel: profile.age == null ? null : '**',
      clearAgeLabel: profile.age == null,
    );
  }
}

class DiscoverMorePage {
  const DiscoverMorePage({required this.others, required this.hasMore});

  final List<DiscoverProfile> others;
  final bool hasMore;
}
