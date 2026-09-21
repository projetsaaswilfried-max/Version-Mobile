import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/safety_providers.dart';
import '../../domain/report_reason.dart';

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final ReportTargetType targetType;
  final String targetId;

  static Future<bool> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    final colors = context.colors;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ReportSheet(targetType: targetType, targetId: targetId),
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) {
      setState(() => _error = 'Choisis un motif.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(safetyRepositoryProvider)
        .report(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reason: reason,
          details: _details.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        Navigator.of(context).pop(true);
      case Err<void>(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Signaler', style: context.typography.headline),
            const SizedBox(height: AppSpacing.md),
            for (final reason in ReportReason.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason.label),
                leading: Icon(
                  _reason == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: () => setState(() => _reason = reason),
              ),
            AppTextField(
              hint: 'Détails (optionnel)',
              controller: _details,
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: context.typography.bodySmall.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Envoyer', isLoading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmAndBlock({
  required BuildContext context,
  required WidgetRef ref,
  required String profileId,
}) async {
  final confirmed = await AppConfirmDialog.show(
    context,
    title: 'Bloquer ce profil ?',
    message:
        'Vous ne pourrez plus vous écrire. Le blocage est immédiat et symétrique.',
    confirmLabel: 'Bloquer',
    icon: Icons.block,
  );
  if (confirmed != true) return false;
  final result = await ref.read(safetyRepositoryProvider).block(profileId);
  return switch (result) {
    Ok<void>() => true,
    Err<void>(:final failure) => () {
      if (context.mounted) {
        final text = failure.message.isEmpty
            ? 'Impossible de bloquer ce profil.'
            : userFacingMessage(failure);
        AppToast.show(context, text);
      }
      return false;
    }(),
  };
}
