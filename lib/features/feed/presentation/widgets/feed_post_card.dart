import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_relative_time.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_verified_badge.dart';
import '../../../safety/domain/report_reason.dart';
import '../../../safety/presentation/widgets/report_sheet.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media_type.dart';
import '../feed_controller.dart';
import '../pages/post_detail_page.dart';
import 'feed_comments_sheet.dart';
import 'feed_post_actions.dart';

class FeedPostCard extends ConsumerStatefulWidget {
  const FeedPostCard({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colors = context.colors;
    final typography = context.typography;
    final title = post.title?.trim();
    final hasTitle = title != null && title.isNotEmpty;

    return VisibilityDetector(
      key: ValueKey('feed-view-${post.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.5) {
          ref.read(feedControllerProvider.notifier).recordView(post);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.lgRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Highlight ET splash transparents : le surlignage plein
              // (affiché tant que le doigt reste posé) restait visible au
              // retour depuis PostDetailPage, la transition de route
              // interrompant l'animation de relâchement du tap.
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PostDetailPage(post: post),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surface,
                            border: Border.all(color: colors.primary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: AppSpacing.lg,
                            backgroundColor: colors.muted,
                            backgroundImage: post.author.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    post.author.avatarUrl!,
                                  )
                                : const AssetImage(AppAssets.appIcon),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.author.displayName,
                                      style: typography.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (post.author.isVerified) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    const AppVerifiedBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _MetaLine(post: post),
                            ],
                          ),
                        ),
                        if (post.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: Icon(
                              Icons.push_pin_outlined,
                              size: AppSpacing.lg,
                              color: colors.primary,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Signaler',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final sent = await ReportSheet.show(
                              context,
                              targetType: ReportTargetType.post,
                              targetId: post.id,
                            );
                            if (sent && context.mounted) {
                              AppToast.show(
                                context,
                                'Signalement envoyé.',
                                isError: false,
                              );
                            }
                          },
                          icon: Icon(
                            Icons.more_horiz,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (hasTitle) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        style: typography.title.copyWith(height: 1.25),
                      ),
                    ],
                    if (post.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _Body(
                        text: post.body,
                        expanded: _expanded,
                        onToggle: () => setState(() => _expanded = !_expanded),
                        quote: post.mediaType == PostMediaType.quoteCard,
                        attribution: post.quoteAttribution,
                      ),
                    ],
                    if (_showMedia(post)) ...[
                      const SizedBox(height: AppSpacing.md),
                      _MediaBlock(post: post),
                    ],
                    FeedPostActions(
                      post: post,
                      onOpenComments: () {
                        FeedCommentsSheet.show(context, post: post);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _showMedia(Post post) {
    return switch (post.mediaType) {
      PostMediaType.textOnly => false,
      PostMediaType.quoteCard => false,
      _ =>
        post.mediaUrls.isNotEmpty ||
            post.imageUrl != null ||
            post.thumbnailUrl != null ||
            post.youtubeUrl != null,
    };
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typography.bodySmall;
    final parts = <Widget>[];

    void addDot() {
      if (parts.isEmpty) return;
      parts.add(
        Text(' · ', style: style.copyWith(color: colors.textSecondary)),
      );
    }

    if (post.createdAt != null) {
      parts.add(
        Text(
          formatRelativeTime(post.createdAt!),
          style: style.copyWith(color: colors.textSecondary),
        ),
      );
    }
    if (post.category != null) {
      addDot();
      parts.add(
        Text(
          post.category!.cardLabel,
          style: style.copyWith(color: colors.textSecondary),
        ),
      );
    }
    addDot();
    parts.add(
      Icon(
        Icons.visibility_outlined,
        size: AppSpacing.md,
        color: colors.textSecondary,
      ),
    );
    parts.add(const SizedBox(width: AppSpacing.xs));
    parts.add(
      Text(
        '${post.viewCount}',
        style: style.copyWith(color: colors.textSecondary),
      ),
    );

    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: parts);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.text,
    required this.expanded,
    required this.onToggle,
    required this.quote,
    this.attribution,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  final bool quote;
  final String? attribution;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final style = quote
        ? typography.bodyLarge.copyWith(height: 1.35)
        : typography.bodyMedium.copyWith(height: 1.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflowing = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: expanded ? null : 4,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (quote && attribution != null && attribution!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  attribution!,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            if (overflowing)
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    expanded ? 'Voir moins' : 'Voir plus',
                    style: typography.label.copyWith(color: colors.primary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final youtube = post.mediaType == PostMediaType.youtube;
    final colors = context.colors;
    final url = post.thumbnailUrl ?? post.imageUrl;
    final showPlay = post.mediaType == PostMediaType.video || youtube;
    final showBadge =
        post.mediaType == PostMediaType.gallery && post.galleryCount > 1;
    final ratio = youtube ? 16 / 9 : 4 / 3;

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              AppNetworkImage(url: url)
            else
              ColoredBox(color: colors.muted),
            if (showPlay)
              Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: AppSpacing.xxxl,
                  color: colors.surface,
                ),
              ),
            if (showBadge)
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.72),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    '${post.galleryCount} photos',
                    style: context.typography.label.copyWith(
                      color: colors.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
