import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/feed_providers.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media_type.dart';
import '../pages/post_detail_page.dart';

/// Grille horizontale des posts `PERSONAL` d'un auteur (PRD §10 / D24).
class ProfilePersonalPostsSection extends ConsumerWidget {
  const ProfilePersonalPostsSection({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = authorId.trim();
    if (id.isEmpty) return const SizedBox.shrink();

    final async = ref.watch(personalPostsByAuthorProvider(id));
    return async.when(
      loading: () => AppProfileSection(
        title: 'Publications',
        child: SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, _) => const AppSkeletonBox(
              width: 112,
              height: 112,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        return AppProfileSection(
          title: 'Publications',
          child: SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: posts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PersonalPostTile(
                  post: post,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PostDetailPage(post: post),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PersonalPostTile extends StatelessWidget {
  const _PersonalPostTile({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  String? get _previewUrl {
    final image = post.imageUrl?.trim();
    if (image != null && image.isNotEmpty) return image;
    final thumb = post.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    for (final url in post.mediaUrls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final url = _previewUrl;
    final isVideo = post.mediaType == PostMediaType.video;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 112,
          height: 112,
          child: url != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: url, fit: BoxFit.cover),
                    if (isVideo)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: colors.scrim.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: colors.onScrim,
                            size: AppSpacing.xl,
                          ),
                        ),
                      ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      post.body.trim().isEmpty ? 'Publication' : post.body,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodySmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
