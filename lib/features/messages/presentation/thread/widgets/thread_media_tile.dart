import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/message.dart';
import '../thread_time_labels.dart';

class ThreadMediaTile extends StatelessWidget {
  const ThreadMediaTile({super.key, required this.message, this.onTap});

  final Message message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final mine = message.senderIsMe;
    final label = switch (message.type) {
      MessageType.image => message.mediaLabel ?? 'Photo',
      MessageType.video => message.mediaLabel ?? 'Vidéo',
      MessageType.document => message.fileName ?? 'Document',
      MessageType.voice =>
        message.durationSeconds == null
            ? 'Note vocale'
            : 'Note vocale · ${message.durationSeconds}s',
      _ => message.mediaLabel ?? 'Média',
    };

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Material(
              color: colors.surface,
              borderRadius: AppRadius.lgRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('thread-media-${message.id}'),
                onTap: onTap,
                child: _preview(context, label),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatThreadClock(message.createdAt),
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, String label) {
    final colors = context.colors;
    final typography = context.typography;
    final url = message.mediaUrl;
    final isVisual =
        (message.type == MessageType.image ||
            message.type == MessageType.video) &&
        url != null &&
        url.isNotEmpty;

    if (isVisual) {
      return Semantics(
        label: label,
        button: true,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.58,
          child: AspectRatio(
              aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: url, semanticLabel: label),
                if (message.type == MessageType.video)
                  ColoredBox(
                    color: colors.scrim.withValues(alpha: 0.28),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: AppSpacing.xxxl,
                        color: colors.onScrim,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final icon = switch (message.type) {
      MessageType.image => Icons.image_outlined,
      MessageType.video => Icons.play_circle_outline,
      MessageType.document => Icons.description_outlined,
      MessageType.voice => Icons.mic_none_outlined,
      _ => Icons.attachment_outlined,
    };

    return Semantics(
      label: label,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: AppRadius.lgRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: typography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
