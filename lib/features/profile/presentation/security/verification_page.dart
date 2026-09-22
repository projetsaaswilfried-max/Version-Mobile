import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/verification_info.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  VerificationInfo? _info;
  var _loading = true;
  var _saving = false;
  String? _error;
  String? _saveError;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchVerification();
    if (!mounted) return;
    switch (result) {
      case Ok<VerificationInfo>(:final value):
        setState(() {
          _info = value;
          _loading = false;
        });
      case Err<VerificationInfo>(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _submit() async {
    final info = _info;
    if (info == null || !info.canSubmit) return;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .submitVerification(selfiePath: file.path);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        await popAfterAccountSave(context, ref, message: 'Demande envoyée.');
      case Err<void>(:final failure):
        setState(() => _saveError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return AccountEditorScaffold(
      title: 'Vérification',
      isLoading: _loading,
      errorMessage: _error,
      onRetry: _load,
      isSaving: _saving,
      saveError: _saveError,
      showSave: info?.canSubmit ?? false,
      saveLabel: 'Soumettre un selfie',
      onSave: _submit,
      child: info == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _StatusHero(info: info),
                if (info.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    icon: Icons.error_outline,
                    color: context.colors.error,
                    title: 'Motif du refus',
                    body: info.rejectionReason!,
                  ),
                ],
                if (info.isPending) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    icon: Icons.schedule,
                    color: context.colors.warning,
                    title: 'Délai d\'examen',
                    body:
                        'Sous 24h si ton abonnement Premium est actif au '
                        'moment de la soumission, sinon sous 48h.',
                  ),
                ],
                if (!info.isComplete) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _RequirementsCard(),
                ],
                if (info.canSubmit) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    icon: Icons.camera_alt_outlined,
                    color: context.colors.primary,
                    title: 'Selfie en direct',
                    body:
                        'Le selfie se prend en direct à la caméra, pas '
                        'depuis la galerie.',
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _BenefitsCard(unlocked: info.isVerified),
              ],
            ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.info});

  final VerificationInfo info;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final (icon, color, subtitle) = switch (info) {
      _ when info.isVerified => (
        Icons.verified,
        colors.success,
        'Ton profil affiche le badge vérifié et inspire confiance.',
      ),
      _ when info.isPending => (
        Icons.hourglass_top,
        colors.warning,
        'Ton dossier est en cours d\'examen par notre équipe.',
      ),
      _ when info.isRejected => (
        Icons.error_outline,
        colors.error,
        'Ta dernière demande a été refusée, vois le motif ci-dessous.',
      ),
      _ => (
        Icons.shield_outlined,
        colors.textSecondary,
        'Vérifie ton profil pour débloquer le badge et gagner en confiance.',
      ),
    };

    return Column(
      children: [
        Container(
          width: AppSpacing.xxxl * 1.6,
          height: AppSpacing.xxxl * 1.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: AppSpacing.xxxl, color: color),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          info.statusLabel,
          style: typography.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSpacing.lg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: typography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(body, style: typography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard();

  static const _items = [
    'Une photo de profil principale',
    'Ta confession',
    'Pourquoi le mariage t\'intéresse',
    'Ta situation matrimoniale',
    'Tes centres d\'intérêt',
    'Ton genre',
    'Ta date de naissance',
    'Ton pays',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complète ton profil pour soumettre',
              style: typography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: AppSpacing.md,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: typography.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.unlocked});

  final bool unlocked;

  static const _items = [
    'Badge vérifié visible sur ton profil',
    'Plus de confiance auprès des autres membres',
    'Accès prioritaire à l\'examen si tu es Premium',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unlocked ? 'Ce que ça te donne' : 'Pourquoi se vérifier ?',
              style: typography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: AppSpacing.md,
                      color: unlocked ? colors.success : colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: typography.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
