import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/post.dart';
import '../feed_comments_controller.dart';
import 'feed_comment_composer.dart';
import 'feed_comments_section.dart';

class FeedCommentsSheet extends ConsumerStatefulWidget {
  const FeedCommentsSheet({super.key, required this.post});

  final Post post;

  static const heightFactor = 3 / 4;

  static Future<void> show(BuildContext context, {required Post post}) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * heightFactor,
            child: FeedCommentsSheet(post: post),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends ConsumerState<FeedCommentsSheet> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final comments = ref.watch(feedCommentsProvider(widget.post.id));
    final notifier = ref.read(feedCommentsProvider(widget.post.id).notifier);
    final canSend = !comments.sending && _composer.text.trim().isNotEmpty;

    ref.listen(feedCommentsProvider(widget.post.id), (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      AppToast.show(context, userFacingMessageFromRaw(message));
    });

    return Material(
      color: colors.surface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: AppRadius.pillRadius,
              ),
              child: const SizedBox(
                width: AppSpacing.xxl,
                height: AppSpacing.xs,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Commentaires', style: typography.title),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                FeedCommentsSection(
                  comments: comments.comments,
                  isLoading: comments.isLoading,
                  errorMessage: comments.errorMessage,
                  onReply: notifier.startReply,
                  onRetry: notifier.load,
                ),
              ],
            ),
          ),
          FeedCommentComposer(
            controller: _composer,
            enabled: canSend,
            replyToName: comments.replyTo?.authorName,
            onClearReply: notifier.clearReply,
            onChanged: () => setState(() {}),
            onSend: () async {
              final sent = await notifier.send(_composer.text);
              if (!mounted || !sent) return;
              _composer.clear();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
