import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/my_profile_photo.dart';

class MyProfilePhotoGrid extends StatelessWidget {
  const MyProfilePhotoGrid({
    super.key,
    required this.photos,
    required this.readOnly,
    required this.onAdd,
    required this.onRemoveAt,
    this.maxSlots = 2,
    this.emphasizeEmpty = false,
    this.showRemoveButtons,
  });

  final int maxSlots;
  final List<MyProfilePhoto> photos;
  final bool readOnly;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  /// Découplé de [readOnly] : un appelant peut vouloir cacher la tuile "+"
  /// inline (l'ajout passe par un autre flux, ex. selfie obligatoire) tout
  /// en gardant la suppression possible. `null` retombe sur `!readOnly`
  /// (comportement historique).
  final bool? showRemoveButtons;

  /// Cadre d'ajout plus visible quand la photo manque pour la complétion.
  final bool emphasizeEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final canAdd = !readOnly && photos.length < maxSlots;
    final canRemove = showRemoveButtons ?? !readOnly;
    final closeIcon = AppSpacing.lg + AppSpacing.xxs;
    final showHeroEmpty = canAdd && photos.isEmpty && emphasizeEmpty;

    if (showHeroEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xlRadius,
                side: BorderSide(color: colors.primary, width: 1.5),
              ),
              child: InkWell(
                borderRadius: AppRadius.xlRadius,
                onTap: onAdd,
                child: Semantics(
                  button: true,
                  label: 'Ajouter une photo',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: AppSpacing.xxxl,
                        color: colors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Ajouter ta photo de profil',
                        style: typography.bodyLarge.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          'Obligatoire pour apparaître dans Découvrir',
                          textAlign: TextAlign.center,
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 0; i < photos.length; i++)
          SizedBox(
            width: AppPhotoGrid.defaultSlotWidth,
            height: AppPhotoGrid.defaultSlotHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.lgRadius,
                  child: _PhotoFill(photo: photos[i]),
                ),
                if (_ModerationBadge.labelFor(photos[i].moderationStatus)
                    case final label?)
                  Positioned(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: _ModerationBadge(label: label),
                  ),
                if (canRemove)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: 'Retirer la photo',
                      onPressed: () => onRemoveAt(i),
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.xxxl,
                        minHeight: AppSpacing.xxxl,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.close, size: closeIcon),
                    ),
                  ),
              ],
            ),
          ),
        if (canAdd)
          SizedBox(
            width: AppPhotoGrid.defaultSlotWidth,
            height: AppPhotoGrid.defaultSlotHeight,
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgRadius,
                side: BorderSide(color: colors.border),
              ),
              child: InkWell(
                borderRadius: AppRadius.lgRadius,
                onTap: onAdd,
                child: Semantics(
                  button: true,
                  label: 'Ajouter une photo',
                  child: Icon(
                    Icons.add,
                    size: AppSpacing.xxl,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoFill extends StatelessWidget {
  const _PhotoFill({required this.photo});

  final MyProfilePhoto photo;

  @override
  Widget build(BuildContext context) {
    final local = photo.localPath;
    if (local != null && local.isNotEmpty) {
      return Image.file(File(local), fit: BoxFit.cover);
    }
    final url = photo.publicUrl;
    if (url != null && url.isNotEmpty) {
      return AppNetworkImage(url: url);
    }
    return const AppAvatarPlaceholder(borderRadius: AppRadius.lgRadius);
  }
}

/// Seuls PENDING/REJECTED sont affichés - APPROVED (déjà visible par les
/// autres membres) et DRAFT (pas encore soumise, rien à signaler) n'ont
/// pas besoin d'un badge.
class _ModerationBadge extends StatelessWidget {
  const _ModerationBadge({required this.label});

  final String label;

  static String? labelFor(String? moderationStatus) {
    switch (moderationStatus?.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'REJECTED':
        return 'Refusée';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isRejected = label == 'Refusée';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isRejected ? colors.error : colors.textPrimary).withValues(
          alpha: 0.85,
        ),
        borderRadius: AppRadius.smRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: typography.label.copyWith(color: colors.onScrim),
          ),
        ),
      ),
    );
  }
}
