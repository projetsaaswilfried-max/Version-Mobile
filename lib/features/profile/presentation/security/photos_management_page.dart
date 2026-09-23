import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/media/crop_profile_image.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/photo_quota.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';
import '../hub/profile_hub_controller.dart';
import '../my_profile/my_profile_page.dart';
import '../my_profile/widgets/my_profile_photo_grid.dart';

class PhotosManagementPage extends ConsumerStatefulWidget {
  const PhotosManagementPage({super.key});

  @override
  ConsumerState<PhotosManagementPage> createState() =>
      _PhotosManagementPageState();
}

class _PhotosManagementPageState extends ConsumerState<PhotosManagementPage> {
  MyProfile? _profile;
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
    final result = await ref.read(getMyProfileProvider)();
    if (!mounted) return;
    switch (result) {
      case Ok<MyProfile>(:final value):
        setState(() {
          _profile = value;
          _loading = false;
        });
      case Err<MyProfile>(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _addVerified() async {
    if (_saving) return;
    final photoPath = await _pickAndCropPhoto();
    if (photoPath == null || !mounted) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Nouveau selfie',
      message:
          'Ajouter une photo après vérification exige un selfie en direct, examiné par l\'équipe.',
      confirmLabel: 'Prendre le selfie',
    );
    if (confirmed != true || !mounted) return;
    final selfie = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (selfie == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .addVerifiedPhoto(photoPath: photoPath, selfiePath: selfie.path);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        await popAfterAccountSave(
          context,
          ref,
          message: 'Photo envoyée pour examen.',
        );
      case Err<void>(:final failure):
        developer.log(
          'addVerifiedPhoto Err: ${failure.runtimeType} - ${failure.message}',
          name: 'profile.photos_management',
        );
        setState(() => _saveError = failure.message);
    }
  }

  /// Choix caméra/galerie + recadrage - c'est la photo de profil, pas le
  /// selfie (celui-ci reste caméra seule, sans recadrage, juste après).
  Future<String?> _pickAndCropPhoto() async {
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
                Text('Ajouter une photo', style: typography.title),
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
    if (source == null || !mounted) return null;
    final file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 85,
    );
    if (file == null || !mounted) return null;
    return cropProfileImage(file.path);
  }

  Future<void> _removeVerifiedAt(int index) async {
    if (_saving) return;
    final profile = _profile;
    if (profile == null || index < 0 || index >= profile.photos.length) {
      return;
    }
    final photo = profile.photos[index];
    final photoId = photo.id;
    if (photoId == null) return;
    // La première photo de la liste est toujours la principale (convention
    // du backend, cf. _fetchPhotos qui la place en tête) - la supprimer
    // réinitialise photo_verification_status à UNVERIFIED côté serveur,
    // même s'il reste d'autres photos (PRD interne §5). `_removeVerifiedAt`
    // n'est câblé que pour un profil déjà vérifié, cette condition suffit.
    final isPrimary = index == 0;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Supprimer cette photo ?',
      message: isPrimary
          ? 'Tu ne seras plus visible par les autres membres dans '
                'Découvrir dès que cette photo sera supprimée. Quand tu '
                'ajouteras une nouvelle photo principale, notre équipe '
                'devra revérifier ton profil avant qu\'il redevienne '
                'visible.'
          : 'Cette photo sera définitivement supprimée.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final result = await ref
        .read(myProfileRepositoryProvider)
        .deletePhoto(photoId);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok<void>():
        // profileFieldsProvider n'est pas autoDispose (cache session) -
        // sans cet invalidate, le bandeau Découvrir/Hub restait sur
        // l'ancien statut (photo principale encore là) tant que l'app
        // n'était pas relancée, même après une suppression réussie.
        ref.invalidate(profileFieldsProvider);
        await ref.read(profileHubControllerProvider.notifier).loadInitial();
        await _load();
      case Err<void>(:final failure):
        developer.log(
          'deletePhoto Err: ${failure.runtimeType} - ${failure.message}',
          name: 'profile.photos_management',
        );
        setState(() => _saveError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final verified = profile?.isVerified ?? false;
    return AccountEditorScaffold(
      title: 'Mes photos',
      isLoading: _loading,
      errorMessage: _error,
      onRetry: _load,
      isSaving: _saving,
      saveError: _saveError,
      showSave: false,
      onSave: null,
      child: profile == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                MyProfilePhotoGrid(
                  photos: profile.photos,
                  readOnly: verified,
                  showRemoveButtons: verified,
                  maxSlots: myProfilePhotoQuota(isPremium: profile.isPremium),
                  onAdd: verified
                      ? _addVerified
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const MyProfilePage(focusPhotos: true),
                          ),
                        ),
                  onRemoveAt: verified
                      ? _removeVerifiedAt
                      : (_) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const MyProfilePage(focusPhotos: true),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  verified
                      ? 'Pour ajouter une photo, un selfie live est obligatoire.'
                      : 'Tant que tu n\'es pas vérifié, gère tes photos dans Mon Profil.',
                  style: context.typography.bodyMedium,
                ),
                if (verified) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Ajouter une photo',
                    isLoading: _saving,
                    onPressed:
                        _saving ||
                            profile.photos.length >=
                                myProfilePhotoQuota(isPremium: profile.isPremium)
                        ? null
                        : _addVerified,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Ouvrir Mon Profil',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const MyProfilePage(focusPhotos: true),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
