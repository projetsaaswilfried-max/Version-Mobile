import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/message.dart';

class ThreadAttachSheet extends StatelessWidget {
  const ThreadAttachSheet({super.key});

  static Future<MessageType?> show(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<MessageType>(
      context: context,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const ThreadAttachSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.md,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Joindre', style: typography.title),
            const SizedBox(height: AppSpacing.md),
            _row(
              context,
              icon: Icons.photo_outlined,
              label: 'Photo',
              type: MessageType.image,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required MessageType type,
  }) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(label, style: context.typography.bodyLarge),
      onTap: () => Navigator.of(context).pop(type),
    );
  }
}
