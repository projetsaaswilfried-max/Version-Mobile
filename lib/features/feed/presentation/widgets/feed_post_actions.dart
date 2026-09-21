import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/post.dart';
import '../feed_controller.dart';

class FeedPostActions extends ConsumerWidget {
  const FeedPostActions({super.key, required this.post, this.onOpenComments});

  final Post post;
  final VoidCallback? onOpenComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Action(
            icon: post.likedByMe
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            color: post.likedByMe ? colors.primary : colors.textSecondary,
            count: post.likeCount,
            label: 'J\'aime',
            onTap: () =>
                ref.read(feedControllerProvider.notifier).toggleLike(post.id),
          ),
          const SizedBox(width: AppSpacing.lg),
          _Action(
            icon: CupertinoIcons.chat_bubble,
            color: colors.textSecondary,
            count: post.commentCount,
            label: 'Commentaires',
            onTap: () => onOpenComments?.call(),
          ),
          const SizedBox(width: AppSpacing.lg),
          _Action(
            icon: CupertinoIcons.square_arrow_up,
            color: colors.textSecondary,
            count: post.shareCount,
            label: 'Partager',
            onTap: () =>
                ref.read(feedControllerProvider.notifier).sharePost(post),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Enregistrer',
            onPressed: () => ref
                .read(feedControllerProvider.notifier)
                .toggleBookmark(post.id),
            icon: Icon(
              post.bookmarkedByMe ? Icons.bookmark : Icons.bookmark_border,
              color: post.bookmarkedByMe
                  ? colors.primary
                  : colors.textSecondary,
              size: AppSpacing.xl,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$count',
                style: typography.bodySmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
