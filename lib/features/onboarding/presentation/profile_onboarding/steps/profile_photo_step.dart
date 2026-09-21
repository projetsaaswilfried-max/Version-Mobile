import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../onboarding_flow_controller.dart';

class ProfilePhotoStep extends ConsumerWidget {
  const ProfilePhotoStep({super.key});

  static const _frameMaxWidth = 340.0;
  /// Cadre d'aperçu carré - aligné sur [CropAspectRatioPreset.square].
  static const _frameAspect = 1.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final photo = state.draft.profilePhotoPath;
    final colors = context.colors;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final helperReserve = AppSpacing.md + AppSpacing.xxl;
                  final maxW = math.min(constraints.maxWidth, _frameMaxWidth);
                  final maxH = math.max(
                    AppSpacing.xxxl * 2,
                    constraints.maxHeight - helperReserve,
                  );
                  var width = maxW;
                  var height = width / _frameAspect;
                  if (height > maxH) {
                    height = maxH;
                    width = height * _frameAspect;
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: width,
                        height: height,
                        child: photo == null
                            ? _EmptyFrame(
                                onTap: () =>
                                    _openSourceSheet(context, controller),
                              )
                            : _FilledFrame(
                                path: photo,
                                onReplace: () =>
                                    _openSourceSheet(context, controller),
                                onRemove: controller.clearProfilePhoto,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        photo == null
                            ? 'Choisis une photo nette de ton visage'
                            : 'Tu peux la remplacer ou la supprimer',
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSourceSheet(
    BuildContext context,
    OnboardingFlowController controller,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final typography = ctx.typography;
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
                const SizedBox(height: AppSpacing.xl),
                Text('Photo de profil', style: typography.title),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: colors.primary,
                  ),
                  title: Text('Prendre une photo', style: typography.bodyLarge),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_outlined, color: colors.primary),
                  title: Text(
                    'Choisir dans la galerie',
                    style: typography.bodyLarge,
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !context.mounted) return;
    await controller.pickProfilePhoto(source);
  }
}

class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.surface,
      borderRadius: AppRadius.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: colors.border),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSpacing.xxxl + AppSpacing.sm,
                  height: AppSpacing.xxxl + AppSpacing.sm,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: AppSpacing.xl,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ajouter une photo',
                  style: typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Caméra ou galerie',
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledFrame extends StatelessWidget {
  const _FilledFrame({
    required this.path,
    required this.onReplace,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _OverlayButton(
              tooltip: 'Supprimer',
              icon: Icons.close_rounded,
              onPressed: onRemove,
              background: colors.scrim.withValues(alpha: 0.55),
              foreground: colors.onScrim,
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Center(
              child: _OverlayButton(
                tooltip: 'Remplacer',
                icon: Icons.cameraswitch_outlined,
                label: 'Remplacer',
                onPressed: onReplace,
                background: colors.scrim.withValues(alpha: 0.55),
                foreground: colors.onScrim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppSpacing.lg + AppSpacing.xs,
                  color: foreground,
                ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label!,
                    style: context.typography.label.copyWith(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.lg),
        ),
      );
    const dashWidth = 7.0;
    const dashSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
