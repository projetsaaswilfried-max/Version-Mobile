import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/user_facing_message.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_toast.dart';
import 'feed_controller.dart';
import 'feed_state.dart';
import 'widgets/feed_category_bar.dart';
import 'widgets/feed_empty_state.dart';
import 'widgets/feed_error_state.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/feed_section_header.dart';
import 'widgets/feed_skeleton.dart';

class FeedBody extends ConsumerStatefulWidget {
  const FeedBody({super.key, this.bottomPadding = AppSpacing.lg});

  final double bottomPadding;

  @override
  ConsumerState<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends ConsumerState<FeedBody> {
  final _scroll = ScrollController();

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
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    ref.listen(feedControllerProvider, (previous, next) {
      final message = next.snackbarMessage;
      if (message == null) return;
      if (message == previous?.snackbarMessage) return;
      AppToast.show(context, userFacingMessageFromRaw(message));
      ref.read(feedControllerProvider.notifier).clearSnackbar();
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: FeedSectionHeader()),
          SliverToBoxAdapter(
            child: FeedCategoryBar(
              selected: state.selectedChip,
              onSelected: (chip) {
                ref.read(feedControllerProvider.notifier).selectFilter(chip);
              },
            ),
          ),
          ..._contentSlivers(state),
        ],
      ),
    );
  }

  List<Widget> _contentSlivers(FeedState state) {
    if (state.isInitialLoading) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: FeedSkeleton()),
      ];
    }
    if (state.errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedErrorState(
            message: 'Impossible de charger le fil',
            onRetry: () => ref.read(feedControllerProvider.notifier).retry(),
          ),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedEmptyState(filtered: !state.filter.isAll),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: widget.bottomPadding,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = state.items[index];
            return FeedPostCard(
              key: ValueKey('feed-post-${post.id}'),
              post: post,
            );
          }, childCount: state.items.length + (state.isLoadingMore ? 1 : 0)),
        ),
      ),
    ];
  }
}
