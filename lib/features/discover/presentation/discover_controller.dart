import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../di/discover_providers.dart';
import '../domain/entities/discover_page.dart';
import '../domain/entities/discover_profile.dart';
import '../domain/entities/discover_query.dart';
import '../domain/filtering/filter_discover_profiles.dart';
import '../domain/usecases/get_discover_page.dart';
import 'discover_state.dart';

typedef _ProfileTransform = DiscoverProfile Function(DiscoverProfile profile);

class DiscoverController extends Notifier<DiscoverState> {
  static const othersPageSize = 12;

  List<DiscoverProfile> _recommendedAll = const [];
  List<DiscoverProfile> _othersAll = const [];
  var _othersVisibleCount = othersPageSize;
  var _serverOffset = GetDiscoverPage.serverBatchSize;
  var _hasMoreServer = false;

  // Contraintes actives (recherche texte et/ou filtres sheet) : requête
  // serveur dédiée, indépendante du vivier `_othersAll` déjà chargé —
  // sinon on ne trouve jamais un profil hors des ~60 premiers candidats
  // en mémoire (bug remonté en test manuel sur la recherche nom).
  List<DiscoverProfile> _searchResults = const [];
  DiscoverQuery? _activeServerQuery;
  var _searchOffset = 0;
  var _searchHasMore = false;

  @override
  DiscoverState build() {
    Future<void>.microtask(loadInitial);
    return const DiscoverState(isInitialLoading: true);
  }

  Future<void> loadInitial() => _load(reset: true, refreshing: false);

  Future<void> applyQuery(DiscoverQuery query) async {
    final normalized = query.normalized;
    state = state.copyWith(query: normalized);
    if (!normalized.hasActiveConstraints) {
      _activeServerQuery = null;
      _othersVisibleCount = othersPageSize;
      _emitVisible();
      return;
    }
    await _runServerQuery(normalized);
  }

  Future<void> clearQuery() async {
    state = state.copyWith(query: const DiscoverQuery());
    _activeServerQuery = null;
    _othersVisibleCount = othersPageSize;
    _emitVisible();
  }

  Future<void> _runServerQuery(DiscoverQuery query) async {
    final visitor = state.visitor;
    if (visitor == null) return;
    _activeServerQuery = query;
    _searchResults = const [];
    _searchOffset = 0;
    _searchHasMore = false;
    state = state.copyWith(
      recommended: const [],
      others: const [],
      isLoadingMore: true,
      hasMoreOthers: false,
      clearError: true,
    );
    final result = await ref
        .read(getDiscoverPageProvider)
        .more(visitor: visitor, offset: 0, query: query);
    if (!ref.mounted || _activeServerQuery != query) return;
    switch (result) {
      case Ok<DiscoverMorePage>(:final value):
        _searchResults = value.others;
        _searchOffset = GetDiscoverPage.serverBatchSize;
        _searchHasMore = value.hasMore;
        state = state.copyWith(
          others: _filter(_searchResults),
          isLoadingMore: false,
          hasMoreOthers: _searchHasMore,
        );
      case Err<DiscoverMorePage>(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> retry() => loadInitial();

  bool isLiked(String profileId) => _findProfile(profileId)?.isLiked ?? false;

  bool isFavorited(String profileId) =>
      _findProfile(profileId)?.isFavorited ?? false;

  Future<bool> toggleLike(String profileId) async {
    final liked = isLiked(profileId);
    final result = liked
        ? await ref.read(unlikeDiscoverProfileProvider)(profileId)
        : await ref.read(likeDiscoverProfileProvider)(profileId);
    if (!ref.mounted) return false;
    if (result is Err) return false;
    _updateProfile(profileId, (p) => p.copyWith(isLiked: !liked));
    return true;
  }

  Future<bool> toggleFavorite(String profileId) async {
    final favorited = isFavorited(profileId);
    final result = favorited
        ? await ref.read(unfavoriteDiscoverProfileProvider)(profileId)
        : await ref.read(favoriteDiscoverProfileProvider)(profileId);
    if (!ref.mounted) return false;
    if (result is Err) return false;
    _updateProfile(profileId, (p) => p.copyWith(isFavorited: !favorited));
    return true;
  }

  DiscoverProfile? _findProfile(String profileId) {
    for (final profile in _recommendedAll) {
      if (profile.id == profileId) return profile;
    }
    for (final profile in _othersAll) {
      if (profile.id == profileId) return profile;
    }
    for (final profile in _searchResults) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  void _updateProfile(String profileId, _ProfileTransform transform) {
    List<DiscoverProfile> apply(List<DiscoverProfile> profiles) => [
      for (final profile in profiles)
        if (profile.id == profileId) transform(profile) else profile,
    ];
    _recommendedAll = apply(_recommendedAll);
    _othersAll = apply(_othersAll);
    _searchResults = apply(_searchResults);
    _emitVisible();
  }

  Future<void> refresh() async {
    final query = state.query.normalized;
    if (query.hasActiveConstraints && state.visitor != null) {
      await _runServerQuery(query);
      return;
    }
    return _load(reset: true, refreshing: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMoreOthers ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.isRefreshing) {
      return;
    }

    if (_activeServerQuery != null) {
      if (!_searchHasMore) return;
      final visitor = state.visitor;
      if (visitor == null) return;
      final query = _activeServerQuery!;
      state = state.copyWith(isLoadingMore: true);
      final result = await ref
          .read(getDiscoverPageProvider)
          .more(visitor: visitor, offset: _searchOffset, query: query);
      if (!ref.mounted || _activeServerQuery != query) return;
      switch (result) {
        case Ok<DiscoverMorePage>(:final value):
          _searchResults = [..._searchResults, ...value.others];
          _searchOffset += GetDiscoverPage.serverBatchSize;
          _searchHasMore = value.hasMore;
          state = state.copyWith(
            others: _filter(_searchResults),
            isLoadingMore: false,
            hasMoreOthers: _searchHasMore,
          );
        case Err<DiscoverMorePage>():
          state = state.copyWith(isLoadingMore: false);
      }
      return;
    }

    final fetchedCount = _filter(_othersAll).length;
    if (_othersVisibleCount < fetchedCount) {
      // Encore du stock déjà téléchargé à révéler — pas d'appel réseau.
      _othersVisibleCount += othersPageSize;
      _emitVisible();
      return;
    }

    if (!_hasMoreServer) return;
    final visitor = state.visitor;
    if (visitor == null) return;

    state = state.copyWith(isLoadingMore: true);
    final result = await ref.read(getDiscoverPageProvider).more(
      visitor: visitor,
      offset: _serverOffset,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok<DiscoverMorePage>(:final value):
        _othersAll = [..._othersAll, ...value.others];
        _serverOffset += GetDiscoverPage.serverBatchSize;
        _hasMoreServer = value.hasMore;
        _othersVisibleCount += othersPageSize;
        _emitVisible();
      case Err<DiscoverMorePage>():
        state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _load({required bool reset, required bool refreshing}) async {
    if (reset) {
      _activeServerQuery = null;
      _searchResults = const [];
      _searchOffset = 0;
      _searchHasMore = false;
    }
    if (refreshing) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else if (reset) {
      state = state.copyWith(
        isInitialLoading: true,
        recommended: const [],
        others: const [],
        hasMoreOthers: false,
        clearError: true,
        clearVisitor: true,
      );
    }

    final result = await ref.read(getDiscoverPageProvider)();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<DiscoverPage>(:final value):
        _recommendedAll = value.recommended;
        _othersAll = value.others;
        _othersVisibleCount = othersPageSize;
        _serverOffset = GetDiscoverPage.serverBatchSize;
        _hasMoreServer = value.hasMoreCandidates;
        state = state.copyWith(
          visitor: value.visitor,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        );
        _emitVisible();
      case Err<DiscoverPage>(:final failure):
        if (refreshing &&
            (_recommendedAll.isNotEmpty || _othersAll.isNotEmpty)) {
          state = state.copyWith(isRefreshing: false, isInitialLoading: false);
        } else {
          _recommendedAll = const [];
          _othersAll = const [];
          _hasMoreServer = false;
          state = state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            recommended: const [],
            others: const [],
            errorMessage: failure.message,
          );
        }
    }
  }

  void _emitVisible() {
    if (_activeServerQuery != null) {
      state = state.copyWith(
        recommended: const [],
        others: _filter(_searchResults),
        hasMoreOthers: _searchHasMore,
        isLoadingMore: false,
      );
      return;
    }
    final recommended = _filter(_recommendedAll);
    final othersAll = _filter(_othersAll);
    final others = othersAll.take(_othersVisibleCount).toList();
    state = state.copyWith(
      recommended: recommended,
      others: others,
      hasMoreOthers: othersAll.length > others.length || _hasMoreServer,
      isLoadingMore: false,
    );
  }

  List<DiscoverProfile> _filter(List<DiscoverProfile> profiles) {
    return filterDiscoverProfiles(profiles, state.query);
  }
}

final discoverControllerProvider =
    NotifierProvider.autoDispose<DiscoverController, DiscoverState>(
      DiscoverController.new,
    );
