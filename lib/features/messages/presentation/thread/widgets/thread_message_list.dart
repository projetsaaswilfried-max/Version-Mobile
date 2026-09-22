import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../premium/presentation/widgets/premium_feature_sheet.dart';
import '../../../domain/composer/thread_composer_mode.dart';
import '../../../domain/entities/message.dart';
import '../conversation_thread_state.dart';
import '../thread_time_labels.dart';
import 'thread_bubble.dart';
import 'thread_composer_bar.dart';
import 'thread_empty.dart';
import 'thread_invite_bar.dart';
import 'thread_media_tile.dart';
import 'thread_voice_tile.dart';

class ThreadMessageList extends StatelessWidget {
  const ThreadMessageList({
    super.key,
    required this.state,
    required this.onSend,
    required this.onAccept,
    required this.onDecline,
    required this.onMediaTap,
    required this.onAttach,
    required this.onSendVoice,
    required this.onDeleteMessage,
  });

  final ConversationThreadState state;
  final ValueChanged<String> onSend;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final ValueChanged<Message> onMediaTap;
  final VoidCallback onAttach;
  final void Function(String path, int durationSeconds) onSendVoice;
  final ValueChanged<Message> onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    final bottom = switch (state.composerMode) {
      ThreadComposerMode.canCompose => ThreadComposerBar(
        enabled: true,
        sending: state.sending,
        onSend: onSend,
        onAttach: onAttach,
        onSendVoice: onSendVoice,
      ),
      ThreadComposerMode.inviteActions => ThreadInviteBar(
        onAccept: onAccept,
        onDecline: onDecline,
        peerName: state.conversation?.peerName,
      ),
      ThreadComposerMode.waitingPeer => const _Banner(
        text: 'En attente de réponse',
      ),
      ThreadComposerMode.readOnlySystem => const _Banner(
        text: 'Les messages Agapeo sont en lecture seule',
      ),
      ThreadComposerMode.premiumRequired => _PremiumBanner(
        onTap: () => PremiumFeatureSheet.show(
          context,
          title: 'Écrire un message',
          message: 'Passe Premium pour écrire dans cette conversation.',
        ),
      ),
    };

    final body = state.messages.isEmpty
        ? ThreadEmpty(
            mode: state.composerMode,
            peerName: state.conversation?.peerName,
          )
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
              final bubble = _bubbleFor(message);
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

  Widget _bubbleFor(Message message) {
    if (message.deleted) return ThreadBubble(message: message);
    final bubble = switch (message.type) {
      MessageType.voice => ThreadVoiceTile(message: message),
      MessageType.image => ThreadMediaTile(
        message: message,
        onTap: (message.mediaUrl?.isNotEmpty ?? false)
            ? () => onMediaTap(message)
            : null,
      ),
      MessageType.video ||
      MessageType.document => ThreadMediaTile(message: message),
      _ => ThreadBubble(message: message),
    };
    // Suppression réservée à l'expéditeur (PRD §19) : long-press déclenche
    // la confirmation portée par la page, pas de menu sur les autres types.
    if (!message.senderIsMe || message.type == MessageType.system) {
      return bubble;
    }
    return GestureDetector(
      onLongPress: () => onDeleteMessage(message),
      child: bubble,
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

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Material(
        color: colors.primary.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Passe Premium pour écrire ici',
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
