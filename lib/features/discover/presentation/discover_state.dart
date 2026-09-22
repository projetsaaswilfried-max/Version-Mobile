import 'package:equatable/equatable.dart';

import '../domain/entities/discover_profile.dart';
import '../domain/entities/discover_query.dart';
import '../domain/entities/visitor_context.dart';
import '../domain/premium/discover_premium_gate.dart';

class DiscoverState extends Equatable {
  const DiscoverState({
    this.query = const DiscoverQuery(),
    this.recommended = const [],
    this.others = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMoreOthers = false,
    this.visitor,
    this.errorMessage,
  });

  final DiscoverQuery query;
  final List<DiscoverProfile> recommended;
  final List<DiscoverProfile> others;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMoreOthers;
  final VisitorContext? visitor;
  final String? errorMessage;

  bool get expired => visitor?.isExpired ?? false;
  bool get visitorVerified => visitor?.isVerified ?? false;
  String get subscriptionStatus => visitor?.subscriptionStatus ?? 'FREE';
  bool get visitorIsStaff => visitor?.isStaff ?? false;
  bool get visitorTraitsIncomplete =>
      visitor != null && hasIncompleteCompatibilityTraits(visitor!.traits);
  bool get visitorPremiumActive => visitor?.isPremiumActive ?? false;

  bool get isEmpty =>
      !isInitialLoading &&
      !isLoadingMore &&
      errorMessage == null &&
      !expired &&
      recommended.isEmpty &&
      others.isEmpty;

  /// Fetch de recherche/filtres : les listes sont vidées le temps de la
  /// requête. Distinct du `loadMore` en bas de liste, pour centrer le
  /// spinner au lieu de le coller en haut du scroll.
  bool get isReloadingResults =>
      isLoadingMore && recommended.isEmpty && others.isEmpty;

  bool get shouldOfferPremiumSheet => shouldShowDiscoverPremiumSheet(
    subscriptionStatus: subscriptionStatus,
    isStaff: visitorIsStaff,
  );

  bool get canUseSearchFilters => canUseDiscoverSearchFilters(
    subscriptionStatus: subscriptionStatus,
    isStaff: visitorIsStaff,
  );

  DiscoverState copyWith({
    DiscoverQuery? query,
    List<DiscoverProfile>? recommended,
    List<DiscoverProfile>? others,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMoreOthers,
    VisitorContext? visitor,
    String? errorMessage,
    bool clearError = false,
    bool clearVisitor = false,
  }) {
    return DiscoverState(
      query: query ?? this.query,
      recommended: recommended ?? this.recommended,
      others: others ?? this.others,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreOthers: hasMoreOthers ?? this.hasMoreOthers,
      visitor: clearVisitor ? null : (visitor ?? this.visitor),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    query,
    recommended,
    others,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasMoreOthers,
    visitor,
    errorMessage,
  ];
}
