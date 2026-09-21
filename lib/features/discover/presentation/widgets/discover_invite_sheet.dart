import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/discover_providers.dart';

class DiscoverInviteSheet extends ConsumerStatefulWidget {
  const DiscoverInviteSheet({
    super.key,
    required this.profileId,
    required this.displayName,
    this.onDismiss,
  });

  final String profileId;
  final String displayName;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    required String profileId,
    required String displayName,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return DiscoverInviteSheet(
          profileId: profileId,
          displayName: displayName,
          onDismiss: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  @override
  ConsumerState<DiscoverInviteSheet> createState() =>
      _DiscoverInviteSheetState();
}

class _DiscoverInviteSheetState extends ConsumerState<DiscoverInviteSheet> {
  final _message = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String? get _trimmedMessage {
    final value = _message.text.trim();
    if (value.isEmpty) return null;
    return value;
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);
    final result = await ref.read(sendDiscoverInvitationProvider)(
      profileId: widget.profileId,
      message: _trimmedMessage,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok():
        widget.onDismiss?.call();
        AppToast.show(context, 'Invitation envoyée', isError: false);
      case Err(:final failure):
        final text = failure.message.trim().isEmpty
            ? 'Invitation impossible.'
            : userFacingMessage(failure);
        AppToast.show(context, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          (bottom > 0 ? bottom : AppSpacing.lg) + keyboard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.displayName, style: typography.headline),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: widget.onDismiss,
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Envoie une invitation pour démarrer la conversation.',
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _message,
              label: 'Message',
              hint: 'Optionnel',
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Envoyer',
              isLoading: _sending,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Annuler',
              variant: AppButtonVariant.secondary,
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
