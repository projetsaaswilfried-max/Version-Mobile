import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_relative_time.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/comments/comment_threads.dart';
import '../../domain/entities/post_comment.dart';
import 'feed_comments_skeleton.dart';

class FeedCommentsSection extends StatefulWidget {
  const FeedCommentsSection({
    super.key,
    required this.comments,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.onReply,
  });

  final List<PostComment> comments;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<PostComment>? onReply;

  @override
  State<FeedCommentsSection> createState() => _FeedCommentsSectionState();
}

class _FeedCommentsSectionState extends State<FeedCommentsSection> {
  final _expanded = <String>{};

  @override
  void didUpdateWidget(FeedCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comments.isEmpty) return;
    final previousIds = {for (final comment in oldWidget.comments) comment.id};
    for (final comment in widget.comments) {
      if (previousIds.contains(comment.id) || comment.parentId == null) {
        continue;
      }
      _expanded.add(replyTarget(comment, widget.comments).id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final threads = groupCommentThreads(widget.comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isLoading)
          const FeedCommentsSkeleton()
        else if (widget.errorMessage != null) ...[
          Text(
            'Impossible de charger les commentaires',
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          if (widget.onRetry != null)
            TextButton(
              onPressed: widget.onRetry,
              child: const Text('Réessayer'),
            ),
        ] else if (widget.comments.isEmpty)
          const AppEmptyState(
            compact: true,
            icon: Icons.chat_bubble_outline,
            title: 'Aucun commentaire pour le moment',
            detail: 'Sois le premier à réagir.',
          )
        else
          for (var i = 0; i < threads.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _CommentThreadView(
              thread: threads[i],
              expanded: _expanded.contains(threads[i].parent.id),
              onReply: widget.onReply,
              onToggleReplies: () {
                setState(() {
                  final id = threads[i].parent.id;
                  if (_expanded.contains(id)) {
                    _expanded.remove(id);
                  } else {
                    _expanded.add(id);
                  }
                });
              },
            ),
          ],
      ],
    );
  }
}

class _CommentThreadView extends StatelessWidget {
  const _CommentThreadView({
    required this.thread,
    required this.expanded,
    required this.onToggleReplies,
    this.onReply,
  });

  final CommentThread thread;
  final bool expanded;
  final VoidCallback onToggleReplies;
  final ValueChanged<PostComment>? onReply;

  @override
  Widget build(BuildContext context) {
    final visible = visibleReplyCount(
      thread.replies.length,
      expanded: expanded,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(comment: thread.parent, onReply: onReply),
        for (var i = 0; i < visible; i++)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xxl,
              top: AppSpacing.sm,
            ),
            child: _CommentTile(comment: thread.replies[i], onReply: onReply),
          ),
        if (thread.replies.length > 2)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxl),
            child: TextButton(
              onPressed: onToggleReplies,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSpacing.xxxl, AppSpacing.xxxl),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                expanded
                    ? 'Masquer les réponses'
                    : thread.replies.length - visible == 1
                    ? 'Voir 1 réponse'
                    : 'Voir les ${thread.replies.length - visible} réponses',
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onReply});

  final PostComment comment;
  final ValueChanged<PostComment>? onReply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final name = comment.authorName.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    const avatarSize = AppSpacing.xl + AppSpacing.sm;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: _CommentAvatar(
              url: comment.authorAvatarUrl,
              initial: initial,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (comment.isVerified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const AppVerifiedBadge(size: AppSpacing.md + AppSpacing.xs),
                  ],
                  if (comment.createdAt != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatRelativeTime(comment.createdAt!),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  borderRadius: AppRadius.xlRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    comment.body,
                    style: typography.bodyMedium.copyWith(height: 1.35),
                  ),
                ),
              ),
              if (onReply != null)
                TextButton(
                  onPressed: () => onReply!(comment),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(AppSpacing.xxxl, AppSpacing.xxxl),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Répondre'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (url != null && url!.isNotEmpty) {
      return AppNetworkImage(url: url!, semanticLabel: 'Photo de profil');
    }
    return ColoredBox(
      color: colors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initial,
          style: context.typography.label.copyWith(color: colors.primary),
        ),
      ),
    );
  }
}
