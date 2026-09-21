import 'package:image_cropper/image_cropper.dart';

import '../theme/app_colors.dart';

/// Crops a picked/captured image before it enters the profile draft.
///
/// Presets natifs du package ([CropAspectRatioPreset.original],
/// [CropAspectRatioPreset.square]) - l'utilisateur choisit librement.
/// Retourne le chemin croppé, ou `null` si annulation.
Future<String?> cropProfileImage(String sourcePath) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    maxWidth: 1600,
    maxHeight: 1600,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Rogner la photo',
        toolbarColor: AppColors.light.primary,
        toolbarWidgetColor: AppColors.light.onScrim,
        statusBarLight: false,
        activeControlsWidgetColor: AppColors.light.primary,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
        aspectRatioPresets: const [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
        ],
      ),
      IOSUiSettings(
        title: 'Rogner la photo',
        doneButtonTitle: 'Valider',
        cancelButtonTitle: 'Annuler',
        aspectRatioLockEnabled: false,
        aspectRatioPresets: const [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
        ],
      ),
    ],
  );
  return cropped?.path;
}
