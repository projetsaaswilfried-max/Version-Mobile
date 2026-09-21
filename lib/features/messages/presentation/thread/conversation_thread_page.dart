import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../safety/domain/report_reason.dart';
import '../../../safety/presentation/widgets/report_sheet.dart';
import '../../domain/entities/message.dart';
import 'conversation_thread_controller.dart';
import 'message_image_viewer_page.dart';
import 'widgets/thread_match_banner.dart';
import 'widgets/thread_message_list.dart';
import 'widgets/thread_attach_sheet.dart';

class ConversationThreadPage extends ConsumerWidget {
  const ConversationThreadPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      conversationThreadControllerProvider(conversationId),
    );
    final notifier = ref.read(
      conversationThreadControllerProvider(conversationId).notifier,
    );

    ref.listen(conversationThreadControllerProvider(conversationId), (
      previous,
      next,
    ) {
      if (next.closed && !(previous?.closed ?? false)) {
        Navigator.of(context).pop();
      }
    });

    final title = state.conversation?.peerName ?? 'Conversation';
    final photoUrl = state.conversation?.peerPhotoUrl;
    final initial = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.lg,
              backgroundColor: context.colors.muted,
              foregroundImage: photoUrl == null
                  ? null
                  : CachedNetworkImageProvider(photoUrl),
              child: photoUrl == null
                  ? Text(initial, style: context.typography.bodySmall)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: context.typography.title,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final peerId = state.conversation?.peerId;
              if (value == 'report' && peerId != null) {
                final sent = await ReportSheet.show(
                  context,
                  targetType: ReportTargetType.profile,
                  targetId: peerId,
                );
                if (sent && context.mounted) {
                  AppToast.show(
                    context,
                    'Signalement envoyé.',
                    isError: false,
                  );
                }
                return;
              }
              if (value == 'block' && peerId != null) {
                final blocked = await confirmAndBlock(
                  context: context,
                  ref: ref,
                  profileId: peerId,
                );
                if (blocked) await notifier.hide();
                return;
              }
              if (value != 'hide') return;
              final confirmed = await AppConfirmDialog.show(
                context,
                title: 'Masquer la discussion ?',
                message:
                    'Elle disparaîtra de ta liste. Ce n\'est pas une '
                    'suppression : elle pourra réapparaître plus tard.',
                confirmLabel: 'Masquer',
              );
              if (confirmed == true) {
                await notifier.hide();
              }
            },
            itemBuilder: (context) => [
              if (state.conversation?.peerId != null) ...[
                const PopupMenuItem(value: 'report', child: Text('Signaler')),
                const PopupMenuItem(value: 'block', child: Text('Bloquer')),
              ],
              const PopupMenuItem(
                value: 'hide',
                child: Text('Masquer la discussion'),
              ),
            ],
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ThreadMatchBanner(
                  mode: state.matchBannerModeValue,
                  onPropose: notifier.proposeMatch,
                  onAccept: notifier.acceptMatch,
                  onDecline: notifier.declineMatch,
                  onCancel: notifier.cancelMatch,
                ),
                Expanded(
                  child: ThreadMessageList(
                    state: state,
                    onSend: notifier.send,
                    onAccept: notifier.accept,
                    onDecline: notifier.decline,
                    onAttach: () async {
                      final type = await ThreadAttachSheet.show(context);
                      if (!context.mounted || type == null) return;
                      AppToast.show(context, 'Média : bientôt', isError: false);
                    },
                    onMediaTap: (message) {
                      final url = message.mediaUrl;
                      if (message.type == MessageType.image &&
                          url != null &&
                          url.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MessageImageViewerPage(
                              imageUrl: url,
                              title: message.mediaLabel,
                            ),
                          ),
                        );
                        return;
                      }
                      AppToast.show(context, 'Média : bientôt', isError: false);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
