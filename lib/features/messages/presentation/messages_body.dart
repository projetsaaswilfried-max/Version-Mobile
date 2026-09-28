import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import 'messages_controller.dart';
import 'messages_state.dart';
import 'thread/conversation_thread_page.dart';
import 'widgets/messages_conversation_tile.dart';
import 'widgets/messages_empty_state.dart';
import 'widgets/messages_error_state.dart';
import 'widgets/messages_search_field.dart';
import 'widgets/messages_skeleton.dart';

class MessagesBody extends ConsumerWidget {
  const MessagesBody({super.key, this.bottomPadding = AppSpacing.lg});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(messagesControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _slivers(context, ref, state),
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    MessagesState state,
  ) {
    if (state.isInitialLoading) {
      return const [SliverToBoxAdapter(child: MessagesSkeleton())];
    }
    if (state.errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessagesErrorState(
            message: 'Impossible de charger Messages',
            onRetry: () =>
                ref.read(messagesControllerProvider.notifier).retry(),
          ),
        ),
      ];
    }

    final search = SliverToBoxAdapter(
      child: MessagesSearchField(
        value: state.searchQuery,
        onChanged: (value) =>
            ref.read(messagesControllerProvider.notifier).setSearchQuery(value),
      ),
    );

    if (state.isEmpty) {
      return [
        search,
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessagesEmptyState(filtered: !state.hasNoConversations),
        ),
      ];
    }

    final items = state.visibleConversations;
    return [
      search,
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final conversation = items[index];
          return MessagesConversationTile(
            key: ValueKey('messages-row-${conversation.id}'),
            conversation: conversation,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConversationThreadPage(
                    conversationId: conversation.id,
                  ),
                ),
              );
            },
          );
        }, childCount: items.length),
      ),
      SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
    ];
  }
}
