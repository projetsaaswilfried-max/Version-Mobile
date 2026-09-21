import 'package:equatable/equatable.dart';

import '../domain/entities/feed_filter.dart';
import '../domain/entities/post.dart';
import '../domain/mapping/feed_chip.dart';

class FeedState extends Equatable {
  const FeedState({
    this.filter = const FeedFilter.all(),
    this.selectedChip = FeedChip.all,
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.snackbarMessage,
  });

  final FeedFilter filter;
  final FeedChip selectedChip;
  final List<Post> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? snackbarMessage;

  bool get isEmpty =>
      !isInitialLoading && errorMessage == null && items.isEmpty;

  FeedState copyWith({
    FeedFilter? filter,
    FeedChip? selectedChip,
    List<Post>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? snackbarMessage,
    bool clearError = false,
    bool clearSnackbar = false,
  }) {
    return FeedState(
      filter: filter ?? this.filter,
      selectedChip: selectedChip ?? this.selectedChip,
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snackbarMessage: clearSnackbar
          ? null
          : (snackbarMessage ?? this.snackbarMessage),
    );
  }

  @override
  List<Object?> get props => [
    filter,
    selectedChip,
    items,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasMore,
    errorMessage,
    snackbarMessage,
  ];
}
