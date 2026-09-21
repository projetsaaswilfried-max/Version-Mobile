import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_relative_time.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media_type.dart';
import '../my_posts_controller.dart';
import 'post_composer_page.dart';
import 'post_detail_page.dart';

class MyPostsPage extends ConsumerWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPostsControllerProvider);
    final notifier = ref.read(myPostsControllerProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Mes publications'),
        actions: [
          if (!state.isLoading && state.errorMessage == null)
            IconButton(
              tooltip: 'Créer une publication',
              onPressed: () => _openComposer(context, ref),
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      floatingActionButton: !state.isLoading &&
              state.errorMessage == null &&
              state.items.isNotEmpty
          ? FloatingActionButton(
              tooltip: 'Créer une publication',
              backgroundColor: colors.primary,
              foregroundColor: colors.onScrim,
              onPressed: () => _openComposer(context, ref),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: state.isLoading
          ? const _MyPostsSkeleton()
          : state.errorMessage != null
          ? AppEmptyState(
              icon: Icons.error_outline,
              title: 'Impossible de charger',
              detail: state.errorMessage,
              actionLabel: 'Réessayer',
              actionVariant: AppButtonVariant.primary,
              onAction: notifier.load,
            )
          : state.items.isEmpty
          ? AppEmptyState(
              illustrationAsset: AppAssets.emptyFeed,
              title: 'Aucune publication pour le moment',
              detail:
                  'Partage une pensée, un verset ou une photo - visible sur ton profil public.',
              actionLabel: 'Créer une publication',
              actionVariant: AppButtonVariant.primary,
              onAction: () => _openComposer(context, ref),
            )
          : RefreshIndicator(
              color: colors.primary,
              onRefresh: () => notifier.load(silent: true),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl * 2,
                ),
                itemCount: state.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final post = state.items[index];
                  return _MyPostCard(
                    post: post,
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailPage(post: post),
                        ),
                      );
                    },
                    onEdit: () =>
                        _openComposer(context, ref, existing: post),
                    onDelete: () => _confirmDelete(context, ref, post),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _openComposer(
    BuildContext context,
    WidgetRef ref, {
    Post? existing,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PostComposerPage(existing: existing)),
    );
    if (saved == true && context.mounted) {
      await ref.read(myPostsControllerProvider.notifier).load(silent: true);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Post post,
  ) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Supprimer cette publication ?',
      message: 'Cette action est définitive.',
      confirmLabel: 'Supprimer',
    );
    if (ok == true && context.mounted) {
      await ref.read(myPostsControllerProvider.notifier).remove(post.id);
    }
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({
    required this.post,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _openActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const _MyPostActionsSheet(),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') onEdit();
    if (action == 'delete') onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final mediaPreview = _mediaPreviewUrl(post);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: AppShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: Stack(
          children: [
            Material(
              color: colors.surface.withValues(alpha: 0),
              child: InkWell(
                onTap: onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (mediaPreview != null)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(url: mediaPreview),
                            if (post.mediaType == PostMediaType.video ||
                                post.mediaType == PostMediaType.youtube)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.scrim.withValues(alpha: 0.28),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: colors.onScrim,
                                    size: AppSpacing.xxl,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: mediaPreview == null
                                  ? AppSpacing.xxxl
                                  : 0,
                            ),
                            child: Text(
                              post.createdAt != null
                                  ? formatRelativeTime(post.createdAt!)
                                  : 'Publication',
                              style: typography.bodySmall.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (post.body.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              post.body,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodyLarge.copyWith(height: 1.4),
                            ),
                          ] else if (mediaPreview == null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Sans texte',
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.favorite_border,
                                count: post.likeCount,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              _StatChip(
                                icon: Icons.mode_comment_outlined,
                                count: post.commentCount,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              _StatChip(
                                icon: Icons.visibility_outlined,
                                count: post.viewCount,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: mediaPreview != null
                    ? colors.scrim.withValues(alpha: 0.45)
                    : colors.chipBackground,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openActions(context),
                  child: SizedBox(
                    width: AppSpacing.xxl,
                    height: AppSpacing.xxl,
                    child: Icon(
                      Icons.more_horiz,
                      size: AppSpacing.lg,
                      color: mediaPreview != null
                          ? colors.onScrim
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _mediaPreviewUrl(Post post) {
    return switch (post.mediaType) {
      PostMediaType.image || PostMediaType.gallery => post.imageUrl,
      PostMediaType.video || PostMediaType.youtube => post.thumbnailUrl,
      PostMediaType.quoteCard || PostMediaType.textOnly => null,
    };
  }
}

class _MyPostActionsSheet extends StatelessWidget {
  const _MyPostActionsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSpacing.md,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Publication', style: typography.title),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined, color: colors.primary),
              title: Text('Modifier', style: typography.bodyLarge),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                'Supprimer',
                style: typography.bodyLarge.copyWith(color: colors.error),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.md + 2, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          style: typography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MyPostsSkeleton extends StatelessWidget {
  const _MyPostsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: context.colors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(
                height: 140,
                width: double.infinity,
                borderRadius: AppRadius.mdRadius,
              ),
              SizedBox(height: AppSpacing.md),
              AppSkeletonBox(
                height: AppSpacing.sm,
                width: AppSpacing.skeletonMetaWidth,
                borderRadius: AppRadius.smRadius,
              ),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(
                height: AppSpacing.md,
                width: double.infinity,
                borderRadius: AppRadius.smRadius,
              ),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(
                height: AppSpacing.md,
                width: AppSpacing.skeletonTitleWidth,
                borderRadius: AppRadius.smRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
