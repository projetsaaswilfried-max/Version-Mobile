import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_svg.dart';

class FeedCommentComposer extends StatelessWidget {
  const FeedCommentComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSend,
    this.replyToName,
    this.onClearReply,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSend;
  final String? replyToName;
  final VoidCallback? onClearReply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hint = replyToName == null
        ? 'Écrire un commentaire'
        : 'Réponse à $replyToName';
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (replyToName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Réponse à $replyToName',
                            style: context.typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Annuler la réponse',
                          onPressed: onClearReply,
                          visualDensity: VisualDensity.compact,
                          icon: AppSvg(
                            AppAssets.icClose,
                            size: AppSpacing.lg,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.chipBackground,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          onChanged: (_) => onChanged(),
                          style: context.typography.bodyLarge,
                          decoration: InputDecoration(
                            hintText: hint,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Envoyer le commentaire',
                      child: Material(
                        color: enabled ? colors.primary : colors.chipBackground,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: enabled ? onSend : null,
                          child: SizedBox(
                            width: AppSpacing.xxxl,
                            height: AppSpacing.xxxl,
                            child: Center(
                              child: AppSvg(
                                AppAssets.icSend,
                                size: AppSpacing.lg,
                                color: enabled
                                    ? colors.surface
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
