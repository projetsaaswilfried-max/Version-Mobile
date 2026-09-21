import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_relative_time.dart';
import '../../domain/entities/conversation_summary.dart';

class MessagesConversationTile extends StatelessWidget {
  const MessagesConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final initial = conversation.peerName.trim().isEmpty
        ? '?'
        : conversation.peerName.trim().characters.first.toUpperCase();

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: AppSpacing.xl,
        backgroundColor: colors.muted,
        foregroundImage: conversation.peerPhotoUrl == null
            ? null
            : CachedNetworkImageProvider(conversation.peerPhotoUrl!),
        child: conversation.peerPhotoUrl == null
            ? Text(initial, style: typography.title)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (conversation.isIncomingInvite) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.primaryLight.withValues(alpha: 0.25),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                'Invitation',
                style: typography.bodySmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: conversation.preview == null
          ? null
          : Text(
              conversation.preview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastAt != null)
            Text(
              formatRelativeTime(conversation.lastAt!),
              style: typography.bodySmall,
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Badge(
              label: Text('${conversation.unreadCount}'),
              backgroundColor: colors.primary,
            ),
          ],
        ],
      ),
    );
  }
}
