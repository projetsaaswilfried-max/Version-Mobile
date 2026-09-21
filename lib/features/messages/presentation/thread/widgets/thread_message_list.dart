import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/composer/thread_composer_mode.dart';
import '../../../domain/entities/message.dart';
import '../conversation_thread_state.dart';
import '../thread_time_labels.dart';
import 'thread_bubble.dart';
import 'thread_composer_bar.dart';
import 'thread_empty.dart';
import 'thread_invite_bar.dart';
import 'thread_media_tile.dart';

class ThreadMessageList extends StatelessWidget {
  const ThreadMessageList({
    super.key,
    required this.state,
    required this.onSend,
    required this.onAccept,
    required this.onDecline,
    required this.onMediaTap,
    required this.onAttach,
  });

  final ConversationThreadState state;
  final ValueChanged<String> onSend;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final ValueChanged<Message> onMediaTap;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final bottom = switch (state.composerMode) {
      ThreadComposerMode.canCompose => ThreadComposerBar(
        enabled: true,
        sending: state.sending,
        onSend: onSend,
        onAttach: onAttach,
      ),
      ThreadComposerMode.inviteActions => ThreadInviteBar(
        onAccept: onAccept,
        onDecline: onDecline,
      ),
      ThreadComposerMode.waitingPeer => const _Banner(
        text: 'En attente de réponse',
      ),
      ThreadComposerMode.readOnlySystem => const _Banner(
        text: 'Les messages Agapeo sont en lecture seule',
      ),
    };

    final body = state.messages.isEmpty
        ? const ThreadEmpty()
        : ListView.builder(
            key: const Key('thread-list'),
            reverse: true,
            padding: const EdgeInsets.only(top: AppSpacing.md),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final chronoIndex = state.messages.length - 1 - index;
              final message = state.messages[chronoIndex];
              final showDay =
                  chronoIndex == 0 ||
                  !isSameCalendarDay(
                    message.createdAt,
                    state.messages[chronoIndex - 1].createdAt,
                  );
              final isMedia = switch (message.type) {
                MessageType.image ||
                MessageType.video ||
                MessageType.document ||
                MessageType.voice => true,
                _ => false,
              };
              final bubble = isMedia && !message.deleted
                  ? ThreadMediaTile(
                      message: message,
                      onTap: () => onMediaTap(message),
                    )
                  : ThreadBubble(message: message);
              if (!showDay) return bubble;
              return Column(
                children: [
                  _DaySeparator(date: message.createdAt),
                  bubble,
                ],
              );
            },
          );

    return Column(
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              state.errorMessage!,
              style: context.typography.bodySmall.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
        Expanded(child: body),
        bottom,
      ],
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        formatThreadDayLabel(date),
        textAlign: TextAlign.center,
        style: context.typography.bodySmall.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        color: context.colors.surface,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
