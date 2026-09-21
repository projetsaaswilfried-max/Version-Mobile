import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_relative_time.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media_type.dart';
import '../../domain/mapping/youtube.dart';
import '../feed_comments_controller.dart';
import '../feed_comments_state.dart';
import '../feed_controller.dart';
import '../widgets/feed_comment_composer.dart';
import '../widgets/feed_comments_section.dart';
import '../widgets/feed_gallery_view.dart';
import '../widgets/feed_post_actions.dart';
import '../widgets/feed_video_player.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentsKey = GlobalKey();
  final _composer = TextEditingController();
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedControllerProvider.notifier).recordView(widget.post);
    });
    if (widget.post.mediaType == PostMediaType.youtube) {
      final urls = widget.post.mediaUrls;
      final raw = widget.post.youtubeUrl ?? (urls.isNotEmpty ? urls.first : '');
      final id = youtubeVideoId(raw);
      if (id != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `ref.listen`/`ref.watch` doivent rester dans l'appel direct de build()
    // de ce ConsumerStatefulElement — les descendre dans _buildScaffold
    // casse quand celle-ci est invoquée depuis le `builder` de
    // YoutubePlayerBuilder (build d'un élément enfant, pas celui-ci).
    final comments = ref.watch(feedCommentsProvider(widget.post.id));
    final notifier = ref.read(feedCommentsProvider(widget.post.id).notifier);
    ref.listen(feedCommentsProvider(widget.post.id), (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      AppToast.show(context, userFacingMessageFromRaw(message));
    });
    final post = _displayPost();

    final youtubeController = _youtubeController;
    if (youtubeController != null) {
      // YoutubePlayerBuilder doit englober toute la page : sans lui, le
      // bouton plein écran fait pivoter l'écran en paysage mais garde la
      // mise en page portrait telle quelle (AppBar, texte, commentaires) au
      // lieu de basculer sur la vidéo seule en plein écran.
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: youtubeController,
          showVideoProgressIndicator: true,
        ),
        builder: (context, player) =>
            _buildScaffold(context, post, player, comments, notifier),
      );
    }
    return _buildScaffold(context, post, null, comments, notifier);
  }

  Widget _buildScaffold(
    BuildContext context,
    Post post,
    Widget? youtubePlayer,
    FeedCommentsState comments,
    FeedCommentsController notifier,
  ) {
    final colors = context.colors;
    final typography = context.typography;
    final title = post.title?.trim();
    final hasTitle = title != null && title.isNotEmpty;
    final quote = post.mediaType == PostMediaType.quoteCard;
    final canSend = !comments.sending && _composer.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(post.category?.cardLabel ?? 'Publication')),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(post.author.displayName, style: typography.title),
                  if (post.createdAt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatRelativeTime(post.createdAt!),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (hasTitle) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(title, style: typography.title.copyWith(height: 1.25)),
                  ],
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      post.body,
                      style: quote
                          ? typography.bodyLarge.copyWith(height: 1.35)
                          : typography.bodyMedium.copyWith(height: 1.35),
                    ),
                  ],
                  if (quote &&
                      post.quoteAttribution != null &&
                      post.quoteAttribution!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      post.quoteAttribution!,
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (_hasMedia(post)) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailMedia(post: post, youtubePlayer: youtubePlayer),
                  ],
                  FeedPostActions(
                    post: post,
                    onOpenComments: () {
                      final ctx = _commentsKey.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 280),
                          alignment: 0.05,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KeyedSubtree(
                    key: _commentsKey,
                    child: FeedCommentsSection(
                      comments: comments.comments,
                      isLoading: comments.isLoading,
                      errorMessage: comments.errorMessage,
                      onReply: notifier.startReply,
                      onRetry: notifier.load,
                    ),
                  ),
                ],
              ),
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

  Post _displayPost() {
    for (final item in ref.watch(feedControllerProvider).items) {
      if (item.id == widget.post.id) return item;
    }
    return widget.post;
  }
}

bool _hasMedia(Post post) {
  return switch (post.mediaType) {
    PostMediaType.textOnly || PostMediaType.quoteCard => false,
    _ =>
      post.mediaUrls.isNotEmpty ||
          post.imageUrl != null ||
          post.thumbnailUrl != null ||
          post.youtubeUrl != null,
  };
}

class _DetailMedia extends StatelessWidget {
  const _DetailMedia({required this.post, this.youtubePlayer});

  final Post post;
  final Widget? youtubePlayer;

  @override
  Widget build(BuildContext context) {
    final urls = post.mediaUrls.isNotEmpty
        ? post.mediaUrls
        : [
            if (post.imageUrl != null) post.imageUrl!,
            if (post.thumbnailUrl != null) post.thumbnailUrl!,
          ];

    return switch (post.mediaType) {
      PostMediaType.gallery => FeedGalleryView(
        urls: urls.isEmpty ? [post.imageUrl ?? ''] : urls,
      ),
      PostMediaType.video => FeedVideoPlayer(
        url:
            post.imageUrl ??
            post.thumbnailUrl ??
            (urls.isNotEmpty ? urls.first : ''),
      ),
      PostMediaType.youtube =>
        youtubePlayer ?? const SizedBox.shrink(),
      _ => ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: urls.isEmpty
              ? ColoredBox(color: context.colors.muted)
              : AppNetworkImage(url: urls.first),
        ),
      ),
    };
  }
}
