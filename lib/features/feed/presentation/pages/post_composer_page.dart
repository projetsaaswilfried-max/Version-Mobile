import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/feed_providers.dart';
import '../../domain/entities/personal_post_media.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media_type.dart';
import '../../domain/personal/personal_post_rules.dart';

class PostComposerPage extends ConsumerStatefulWidget {
  const PostComposerPage({super.key, this.existing});

  final Post? existing;

  @override
  ConsumerState<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends ConsumerState<PostComposerPage> {
  late final TextEditingController _body;
  PersonalPostMedia? _media;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  int get _usedChars => _body.text.characters.length;

  int get _remaining => PersonalPostRules.maxChars - _usedChars;

  bool get _canPublish {
    if (_saving) return false;
    if (_usedChars > PersonalPostRules.maxChars) return false;
    final trimmed = _body.text.trim();
    if (_editing) return trimmed.isNotEmpty || _existingHasMedia;
    return trimmed.isNotEmpty || _media != null;
  }

  bool get _existingHasMedia {
    final post = widget.existing;
    if (post == null) return false;
    return post.mediaType != PostMediaType.textOnly &&
        post.mediaType != PostMediaType.quoteCard;
  }

  String? get _existingMediaUrl {
    final post = widget.existing;
    if (post == null) return null;
    return switch (post.mediaType) {
      PostMediaType.image || PostMediaType.gallery => post.imageUrl,
      PostMediaType.video ||
      PostMediaType.youtube => post.thumbnailUrl ?? post.imageUrl,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canPublish) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = _editing
        ? await ref.read(updatePersonalPostProvider)(
            postId: widget.existing!.id,
            body: _body.text,
          )
        : await ref.read(createPersonalPostProvider)(
            body: _body.text,
            media: _media,
          );
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _pickMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final typography = ctx.typography;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Ajouter un média', style: typography.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Une seule image (15 Mo max) ou une vidéo.',
                  textAlign: TextAlign.center,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: colors.primary,
                  ),
                  title: Text('Prendre une photo', style: typography.bodyLarge),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_outlined, color: colors.primary),
                  title: Text('Galerie photo', style: typography.bodyLarge),
                  onTap: () => Navigator.pop(ctx, 'photo'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.videocam_outlined, color: colors.primary),
                  title: Text('Galerie vidéo', style: typography.bodyLarge),
                  onTap: () => Navigator.pop(ctx, 'video'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final picker = ImagePicker();
    final file = choice == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(
            source: choice == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery,
            imageQuality: 85,
          );
    if (file == null || !mounted) return;
    final bytes = await File(file.path).length();
    setState(() {
      _media = PersonalPostMedia(
        localPath: file.path,
        byteSize: bytes,
        isVideo: choice == 'video',
      );
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final counterColor = _remaining < 0
        ? colors.error
        : _remaining <= 40
        ? colors.warning
        : colors.textSecondary;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            _editing ? 'Modifier la publication' : 'Nouvelle publication',
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: _canPublish ? _save : null,
                child: _saving
                    ? SizedBox(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xxs,
                          color: colors.primary,
                        ),
                      )
                    : Text(
                        _editing ? 'Enregistrer' : 'Publier',
                        style: typography.label.copyWith(
                          color: _canPublish
                              ? colors.primary
                              : colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.06),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: AppSpacing.lg,
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Visible sur ton profil public - pas dans le Fil principal.',
                              style: typography.bodySmall.copyWith(
                                color: colors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _body,
                    autofocus: !_editing,
                    minLines: 6,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    style: typography.bodyLarge.copyWith(height: 1.45),
                    decoration: InputDecoration(
                      hintText: 'Partage un moment, un verset, une pensée…',
                      hintStyle: typography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      errorText: _error,
                    ),
                  ),
                  if (_media != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _LocalMediaPreview(
                      media: _media!,
                      onRemove: () => setState(() => _media = null),
                    ),
                  ] else if (_editing && _existingMediaUrl != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ExistingMediaPreview(
                      url: _existingMediaUrl!,
                      isVideo:
                          widget.existing!.mediaType == PostMediaType.video ||
                          widget.existing!.mediaType == PostMediaType.youtube,
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      if (!_editing)
                        IconButton(
                          tooltip: 'Ajouter un média',
                          onPressed: _saving ? null : _pickMedia,
                          icon: Icon(
                            Icons.image_outlined,
                            color: colors.primary,
                          ),
                        ),
                      if (!_editing && _media != null)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _media = null),
                          child: Text(
                            'Retirer le média',
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '$_usedChars / ${PersonalPostRules.maxChars}',
                        style: typography.bodySmall.copyWith(
                          color: counterColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _LocalMediaPreview extends StatelessWidget {
  const _LocalMediaPreview({required this.media, required this.onRemove});

  final PersonalPostMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.isVideo)
              ColoredBox(
                color: colors.chipBackground,
                child: Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: AppSpacing.xxl,
                    color: colors.primary,
                  ),
                ),
              )
            else
              Image.file(File(media.localPath), fit: BoxFit.cover),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: colors.scrim.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Retirer',
                  onPressed: onRemove,
                  icon: Icon(Icons.close, color: colors.onScrim),
                ),
              ),
            ),
            if (media.isVideo)
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.scrim.withValues(alpha: 0.55),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'Vidéo',
                      style: context.typography.bodySmall.copyWith(
                        color: colors.onScrim,
                        fontWeight: FontWeight.w600,
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
}

class _ExistingMediaPreview extends StatelessWidget {
  const _ExistingMediaPreview({required this.url, required this.isVideo});

  final String url;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Média actuel (non modifiable ici)',
          style: context.typography.bodySmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.lgRadius,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: url),
                if (isVideo)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.scrim.withValues(alpha: 0.25),
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
        ),
      ],
    );
  }
}
