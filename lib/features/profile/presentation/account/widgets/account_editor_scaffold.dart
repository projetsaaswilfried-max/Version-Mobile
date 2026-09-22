import 'package:flutter/material.dart';

import '../../../../../core/error/user_facing_message.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

class AccountEditorScaffold extends StatefulWidget {
  const AccountEditorScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.isSaving,
    required this.onSave,
    required this.child,
    this.saveError,
    this.saveLabel = 'Enregistrer',
    this.showSave = true,
  });

  final String title;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool isSaving;
  final VoidCallback? onSave;
  final Widget child;
  final String? saveError;
  final String saveLabel;
  final bool showSave;

  @override
  State<AccountEditorScaffold> createState() => _AccountEditorScaffoldState();
}

class _AccountEditorScaffoldState extends State<AccountEditorScaffold> {
  @override
  void didUpdateWidget(covariant AccountEditorScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = widget.saveError;
    if (error != null && error != oldWidget.saveError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.show(context, userFacingMessageFromRaw(error));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.isLoading
          ? const _Skeleton()
          : widget.errorMessage != null
          ? _Error(message: widget.errorMessage!, onRetry: widget.onRetry)
          : Column(
              children: [
                Expanded(child: widget.child),
                if (widget.showSave)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: AppButton(
                      label: widget.saveLabel,
                      isLoading: widget.isSaving,
                      onPressed: widget.onSave,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(
            height: AppSpacing.md,
            width: AppSpacing.skeletonMetaWidth,
            borderRadius: AppRadius.smRadius,
          ),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(
            height: AppSpacing.xxxl,
            width: double.infinity,
            borderRadius: AppRadius.mdRadius,
          ),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(
            height: AppSpacing.md,
            width: AppSpacing.skeletonTitleWidth,
            borderRadius: AppRadius.smRadius,
          ),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(
            height: AppSpacing.xxxl,
            width: double.infinity,
            borderRadius: AppRadius.mdRadius,
          ),
          SizedBox(height: AppSpacing.lg),
          AppSkeletonBox(
            height: AppSpacing.md,
            width: AppSpacing.skeletonMetaWidth + AppSpacing.lg,
            borderRadius: AppRadius.smRadius,
          ),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(
            height: AppSpacing.xxxl * 2,
            width: double.infinity,
            borderRadius: AppRadius.mdRadius,
          ),
          SizedBox(height: AppSpacing.xl),
          _SkeletonListRow(),
          SizedBox(height: AppSpacing.md),
          _SkeletonListRow(),
          SizedBox(height: AppSpacing.md),
          _SkeletonListRow(),
        ],
      ),
    );
  }
}

class _SkeletonListRow extends StatelessWidget {
  const _SkeletonListRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppSkeletonBox(
          width: AppSpacing.xxxl,
          height: AppSpacing.xxxl,
          shape: BoxShape.circle,
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(
                height: AppSpacing.md,
                width: AppSpacing.skeletonTitleWidth,
                borderRadius: AppRadius.smRadius,
              ),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(
                height: AppSpacing.sm + 2,
                width: AppSpacing.skeletonMetaWidth,
                borderRadius: AppRadius.smRadius,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.typography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
