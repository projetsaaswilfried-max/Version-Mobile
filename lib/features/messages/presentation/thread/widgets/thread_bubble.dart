import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/message.dart';
import '../thread_time_labels.dart';

class ThreadBubble extends StatelessWidget {
  const ThreadBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final text = messageDisplayText(message);

    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
      );
    }

    final mine = message.senderIsMe;
    final fill = mine ? colors.primary : colors.chipBackground;
    final textColor = message.deleted
        ? (mine ? colors.onScrim.withValues(alpha: 0.8) : colors.textSecondary)
        : (mine ? colors.onScrim : colors.textPrimary);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.lg),
      topRight: const Radius.circular(AppRadius.lg),
      bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.sm),
      bottomRight: Radius.circular(mine ? AppRadius.sm : AppRadius.lg),
    );

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
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, borderRadius: radius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    text,
                    style: typography.bodyMedium.copyWith(
                      fontStyle: message.deleted
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: textColor,
                    ),
                  ),
                ),
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
}
