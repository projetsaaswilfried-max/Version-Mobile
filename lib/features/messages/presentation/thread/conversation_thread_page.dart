import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/media/crop_profile_image.dart';
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
import 'widgets/thread_options_sheet.dart';

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
          if (state.conversation?.peerId != null)
            IconButton(
              tooltip: 'Options',
              icon: const Icon(Icons.more_horiz),
              onPressed: () async {
                final peerId = state.conversation!.peerId!;
                final action = await ThreadOptionsSheet.show(context);
                if (!context.mounted || action == null) return;

                switch (action) {
                  case ThreadOptionsAction.report:
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
                  case ThreadOptionsAction.block:
                    final blocked = await confirmAndBlock(
                      context: context,
                      ref: ref,
                      profileId: peerId,
                    );
                    if (blocked) await notifier.hide();
                }
              },
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ThreadMatchBanner(
                  mode: state.matchBannerModeValue,
                  onPropose: () async {
                    final peerName =
                        state.conversation?.peerName ?? 'cette personne';
                    final confirmed = await AppConfirmDialog.show(
                      context,
                      title: 'Proposer un match à $peerName ?',
                      message:
                          'Si $peerName accepte, vous serez officiellement '
                          'en couple : vos deux profils disparaîtront de '
                          'Découvrir pour tout le monde. Un seul match '
                          'actif à la fois est possible.',
                      confirmLabel: 'Proposer',
                    );
                    if (confirmed != true || !context.mounted) return;
                    await notifier.proposeMatch();
                  },
                  onAccept: () async {
                    final peerName =
                        state.conversation?.peerName ?? 'cette personne';
                    final confirmed = await AppConfirmDialog.show(
                      context,
                      title: 'Accepter le match avec $peerName ?',
                      message:
                          'Vous serez officiellement en couple : vos deux '
                          'profils disparaîtront de Découvrir pour tout le '
                          'monde.',
                      confirmLabel: 'Confirmer le match',
                    );
                    if (confirmed != true || !context.mounted) return;
                    await notifier.acceptMatch();
                  },
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
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (picked == null || !context.mounted) return;
                      final croppedPath = await cropProfileImage(picked.path);
                      if (croppedPath == null || !context.mounted) return;
                      await notifier.sendImage(croppedPath);
                      if (!context.mounted) return;
                      final error = ref
                          .read(
                            conversationThreadControllerProvider(
                              conversationId,
                            ),
                          )
                          .errorMessage;
                      if (error != null) {
                        AppToast.show(context, error);
                      }
                    },
                    onSendVoice: (path, durationSeconds) async {
                      await notifier.sendVoice(
                        path,
                        durationSeconds: durationSeconds,
                      );
                      if (!context.mounted) return;
                      final error = ref
                          .read(
                            conversationThreadControllerProvider(
                              conversationId,
                            ),
                          )
                          .errorMessage;
                      if (error != null) {
                        AppToast.show(context, error);
                      }
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
                      }
                    },
                    onDeleteMessage: (message) async {
                      final confirmed = await AppConfirmDialog.show(
                        context,
                        title: 'Supprimer ce message ?',
                        message:
                            'Il sera remplacé par "Message supprimé" pour '
                            'tout le monde. Action irréversible.',
                        confirmLabel: 'Supprimer',
                      );
                      if (confirmed != true || !context.mounted) return;
                      await notifier.deleteMessage(message.id);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
