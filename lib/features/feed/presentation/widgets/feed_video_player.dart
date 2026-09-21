import 'dart:developer' as developer;

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton_box.dart';

/// Lecture vidéo avec les contrôles standards (lecture/pause, barre de
/// progression, son, plein écran) fournis par Chewie — pas besoin de les
/// reconstruire à la main par-dessus video_player.
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _hasError = true;
      return;
    }
    final videoController = VideoPlayerController.networkUrl(uri);
    _videoController = videoController;
    videoController.initialize().then(
      (_) {
        if (!mounted) return;
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: videoController,
            aspectRatio: videoController.value.aspectRatio == 0
                ? 16 / 9
                : videoController.value.aspectRatio,
            autoPlay: false,
            looping: false,
            errorBuilder: (context, errorMessage) => _ErrorPlaceholder(),
          );
        });
      },
      // ExoPlayer lève une PlatformException si le fichier n'est pas un
      // conteneur vidéo reconnu (ex. .mov renommé en .mp4 sans transcodage
      // réel) — sans ce handler, l'exception remonte non gérée et crash.
      onError: (Object error, StackTrace _) {
        developer.log(
          'Vidéo illisible : ${widget.url}',
          name: 'FeedVideoPlayer',
          error: error,
        );
        if (!mounted) return;
        setState(() => _hasError = true);
      },
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    if (_hasError) {
      return const AspectRatio(aspectRatio: 16 / 9, child: _ErrorPlaceholder());
    }
    if (chewieController == null) {
      return const AspectRatio(aspectRatio: 16 / 9, child: _LoadingPlaceholder());
    }
    return AspectRatio(
      aspectRatio: chewieController.aspectRatio ?? 16 / 9,
      child: Chewie(controller: chewieController),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppSkeletonBox(),
        Center(
          child: Icon(
            Icons.play_circle_outline,
            color: context.colors.surface,
            size: 40,
          ),
        ),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.muted,
      child: Center(
        child: Icon(Icons.videocam_off_outlined, color: colors.textSecondary),
      ),
    );
  }
}
