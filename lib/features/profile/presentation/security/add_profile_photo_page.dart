import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/media/crop_profile_image.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/profile_providers.dart';
import '../my_profile/my_profile_controller.dart';
import 'verification_page.dart';

/// Étape 1/2 de la vérification (D34) : photo de profil seule, à part de
/// "Mon Profil" - jamais mélangée avec le selfie sur le même écran.
/// Une fois enregistrée, enchaîne sur [VerificationPage] (étape 2/2).
class AddProfilePhotoPage extends ConsumerStatefulWidget {
  const AddProfilePhotoPage({super.key});

  @override
  ConsumerState<AddProfilePhotoPage> createState() =>
      _AddProfilePhotoPageState();
}

class _AddProfilePhotoPageState extends ConsumerState<AddProfilePhotoPage> {
  String? _photoPath;
  var _saving = false;
  String? _error;

  Future<void> _openSourceSheet() async {
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
    if (source == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final cropped = await cropProfileImage(file.path);
    if (cropped == null || !mounted) return;
    setState(() => _photoPath = cropped);
  }

  Future<void> _next() async {
    if (_saving) return;
    final profileState = ref.read(myProfileControllerProvider);
    final profile = profileState.profile;
    if (profile == null) return;
    final photoPath = _photoPath;
    // Rien de nouveau choisi mais une photo existe déjà (ex. resoumission
    // après refus où seul le selfie doit être refait) : on passe direct.
    if (photoPath == null) {
      if (profile.photos.isEmpty) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VerificationPage()),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(myProfileControllerProvider.notifier);
    // Remplace la photo existante (elle est peut-être la cause du refus)
    // plutôt que d'en ajouter une deuxième à côté.
    while (ref.read(myProfileControllerProvider).profile!.photos.isNotEmpty) {
      notifier.removePhotoAt(0);
    }
    notifier.addLocalPhoto(photoPath);
    final saved = await notifier.save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      setState(() {
        _error = ref.read(myProfileControllerProvider).saveError ??
            'Impossible d\'enregistrer la photo.';
      });
      return;
    }
    // Sans ça, le bandeau Découvrir/Hub reste sur "profil incomplet" tant
    // que l'app n'est pas relancée (profileFieldsProvider n'est pas
    // autoDispose, il ne se recharge jamais seul).
    ref.invalidate(profileFieldsProvider);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const VerificationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    // Le profil doit être chargé avant d'ajouter/enregistrer une photo,
    // sinon addLocalPhoto()/save() échouent silencieusement (profile==null).
    final profileState = ref.watch(myProfileControllerProvider);
    final profile = profileState.profile;
    final ready = profile != null;
    final existingPhotoUrl =
        _photoPath == null && (profile?.photos.isNotEmpty ?? false)
        ? profile!.photos.first.publicUrl
        : null;
    final hasPhoto = _photoPath != null || existingPhotoUrl != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tes photos')),
      body: SafeArea(
        child: profileState.isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : profileState.errorMessage != null && profileState.profile == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profileState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: typography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Réessayer',
                        expanded: false,
                        onPressed: () => ref
                            .read(myProfileControllerProvider.notifier)
                            .retry(),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ajoute au moins une vraie photo - obligatoire pour '
                      'continuer. La première ajoutée devient ta photo '
                      'principale. Juste après, on te demandera un selfie '
                      'en direct pour confirmer que c\'est bien toi.',
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AspectRatio(
                      aspectRatio: 1,
                      child: _PhotoFrame(
                        localPath: _photoPath,
                        networkUrl: existingPhotoUrl,
                        onTap: _openSourceSheet,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(_error!, style: TextStyle(color: colors.error)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Suivant',
                      isLoading: _saving,
                      onPressed: !hasPhoto || _saving || !ready
                          ? null
                          : _next,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({
    required this.localPath,
    required this.networkUrl,
    required this.onTap,
  });

  final String? localPath;
  final String? networkUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final path = localPath;
    final url = networkUrl;

    if (path != null || url != null) {
      return ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            path != null
                ? Image.file(File(path), fit: BoxFit.cover)
                : AppNetworkImage(url: url!),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Material(
                color: colors.scrim.withValues(alpha: 0.55),
                borderRadius: AppRadius.pillRadius,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.pillRadius,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.cameraswitch_outlined,
                      color: colors.onScrim,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: AppSpacing.xl,
                  color: colors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Ajouter une photo', style: typography.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
