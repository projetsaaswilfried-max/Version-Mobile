import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/photo_quota.dart';
import '../account/account_save_feedback.dart';
import '../account/widgets/account_editor_scaffold.dart';
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
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
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
        .addVerifiedPhoto(photoPath: photo.path, selfiePath: selfie.path);
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
                  maxSlots: myProfilePhotoQuota(isPremium: profile.isPremium),
                  onAdd: verified
                      ? _addVerified
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const MyProfilePage(focusPhotos: true),
                          ),
                        ),
                  onRemoveAt: (_) {},
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
                    onPressed:
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
