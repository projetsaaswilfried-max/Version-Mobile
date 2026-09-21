import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/entities/discover_profile.dart';
import '../domain/premium/discover_premium_gate.dart';
import 'discover_controller.dart';
import 'discover_open_profile_sheet.dart';
import 'discover_state.dart';
import '../domain/entities/discover_query.dart';
import 'widgets/discover_card.dart';
import 'widgets/discover_empty_state.dart';
import 'widgets/discover_error_state.dart';
import 'widgets/discover_expired_gate.dart';
import 'widgets/discover_filters_sheet.dart';
import 'widgets/discover_premium_sheet.dart';
import 'search/discover_search_page.dart';
import 'widgets/discover_skeleton.dart';
import 'widgets/discover_toolbar.dart';
import 'widgets/discover_verify_sheet.dart';

class DiscoverBody extends ConsumerStatefulWidget {
  const DiscoverBody({super.key, this.bottomPadding = AppSpacing.lg});

  final double bottomPadding;

  @override
  ConsumerState<DiscoverBody> createState() => _DiscoverBodyState();
}

class _DiscoverBodyState extends ConsumerState<DiscoverBody> {
  final _scroll = ScrollController();
  var _sheetOfferedForLoad = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(discoverControllerProvider.notifier).loadMore();
    }
  }

  void _maybeOfferPremiumSheet(DiscoverState state) {
    if (_sheetOfferedForLoad) return;
    if (state.isInitialLoading || state.isRefreshing) return;
    if (state.expired || state.errorMessage != null) return;
    if (!state.shouldOfferPremiumSheet) return;
    _sheetOfferedForLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DiscoverPremiumSheet.show(context);
    });
  }

  void _onVerifyProfile() {
    AppToast.show(
      context,
      'Vérification du profil : bientôt',
      isError: false,
    );
  }

  void _onSearchOrFiltersLocked() => DiscoverPremiumSheet.show(context);

  void _onProfileTap(DiscoverProfile profile) {
    final state = ref.read(discoverControllerProvider);
    // Ouvrir une fiche complète est débloqué par la vérification seule
    // (Q1, docs/decisions.md) — le Premium ne gate que le contact.
    final canOpen = canOpenDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    );
    if (!canOpen) {
      DiscoverVerifySheet.show(context, onVerify: _onVerifyProfile);
      return;
    }
    openDiscoverProfileSheet(
      context,
      profile: profile,
      state: state,
      onVerifyProfile: _onVerifyProfile,
    );
  }

  void _onLikePressed(DiscoverProfile profile) {
    final state = ref.read(discoverControllerProvider);
    final canLike = canLikeDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    );
    if (!canLike) {
      DiscoverVerifySheet.show(context, onVerify: _onVerifyProfile);
      return;
    }
    unawaited(_toggleLike(profile.id));
  }

  Future<void> _toggleLike(String profileId) async {
    final ok = await ref
        .read(discoverControllerProvider.notifier)
        .toggleLike(profileId);
    if (!ok && mounted) {
      AppToast.show(context, "Impossible d'aimer ce profil.");
    }
  }

  void _onFavoritePressed(DiscoverProfile profile) {
    final state = ref.read(discoverControllerProvider);
    final canFavorite = canFavoriteDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    );
    if (!canFavorite) {
      DiscoverVerifySheet.show(context, onVerify: _onVerifyProfile);
      return;
    }
    unawaited(_toggleFavorite(profile.id));
  }

  Future<void> _toggleFavorite(String profileId) async {
    final ok = await ref
        .read(discoverControllerProvider.notifier)
        .toggleFavorite(profileId);
    if (!ok && mounted) {
      AppToast.show(context, 'Impossible de mettre en favori.');
    }
  }

  void _onSearchTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DiscoverSearchPage()));
  }

  void _onUnlockedFilters() {
    final current = ref.read(discoverControllerProvider);
    DiscoverFiltersSheet.show(
      context,
      initialQuery: current.query,
      onApply: (filters) {
        ref
            .read(discoverControllerProvider.notifier)
            .applyQuery(
              DiscoverQuery(
                search: current.query.search,
                city: filters.city,
                denomination: filters.denomination,
                profession: filters.profession,
              ),
            );
      },
      onReset: () {
        ref.read(discoverControllerProvider.notifier).clearQuery();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    ref.listen(discoverControllerProvider, (previous, next) {
      final finishedLoad =
          previous != null &&
          ((previous.isInitialLoading && !next.isInitialLoading) ||
              (previous.isRefreshing && !next.isRefreshing));
      if (finishedLoad) {
        _sheetOfferedForLoad = false;
      }
      _maybeOfferPremiumSheet(next);
    });
    _maybeOfferPremiumSheet(state);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Text('Découvrir'),
        ),
        actions:
            state.isInitialLoading || state.expired || state.errorMessage != null
            ? null
            : [
                DiscoverToolbar(
                  unlocked: state.canUseSearchFilters,
                  filtersActive: state.query.hasSheetFilters,
                  onLockedTap: _onSearchOrFiltersLocked,
                  onSearchTap: _onSearchTap,
                  onFiltersTap: _onUnlockedFilters,
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          _sheetOfferedForLoad = false;
          return ref.read(discoverControllerProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _contentSlivers(context, state),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(BuildContext context, DiscoverState state) {
    if (state.isInitialLoading) {
      return const [SliverToBoxAdapter(child: DiscoverSkeleton())];
    }
    if (state.expired) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: DiscoverExpiredGate()),
      ];
    }
    if (state.errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: DiscoverErrorState(
            message: 'Impossible de charger Découvrir',
            onRetry: () {
              _sheetOfferedForLoad = false;
              ref.read(discoverControllerProvider.notifier).retry();
            },
          ),
        ),
      ];
    }

    if (state.isEmpty) {
      final hasFilters = state.query.hasActiveConstraints;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: DiscoverEmptyState(
            hasActiveFilters: hasFilters,
            onClearFilters: hasFilters
                ? () =>
                    ref.read(discoverControllerProvider.notifier).clearQuery()
                : null,
          ),
        ),
      ];
    }

    return [
      ..._section(
        context,
        title: 'Recommandée pour vous',
        profiles: state.recommended,
      ),
      ..._section(context, title: 'Autres profils', profiles: state.others),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
    ];
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required List<DiscoverProfile> profiles,
  }) {
    if (profiles.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            title,
            style: context.typography.title.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final profile = profiles[index];
          return DiscoverCard(
            key: ValueKey('discover-card-${profile.id}'),
            profile: profile,
            onTap: () => _onProfileTap(profile),
            onLikePressed: () => _onLikePressed(profile),
            onFavoritePressed: () => _onFavoritePressed(profile),
          );
        }, childCount: profiles.length),
      ),
    ];
  }
}
