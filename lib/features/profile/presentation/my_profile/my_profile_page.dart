import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/church_denominations.dart';
import '../../../../core/media/crop_profile_image.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_option_mapping.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/faith_details.dart';
import '../../domain/mapping/marital_status_label.dart';
import '../../domain/photo_quota.dart';
import '../faith/faith_page.dart';
import '../hub/profile_hub_controller.dart';
import 'my_profile_controller.dart';
import 'widgets/my_profile_photo_grid.dart';

class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key, this.focusPhotos = false});

  /// Depuis la bannière de complétion quand la photo manque.
  final bool focusPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: state.isInitialLoading
          ? const _Skeleton()
          : state.errorMessage != null && state.profile == null
          ? _Error(
              onRetry: () =>
                  ref.read(myProfileControllerProvider.notifier).retry(),
            )
          : _MyProfileForm(
              bottomInset: MediaQuery.paddingOf(context).bottom,
              focusPhotos: focusPhotos,
            ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

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
              'Impossible de charger le profil',
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
            height: AppPhotoGrid.defaultSlotHeight,
            width: AppPhotoGrid.defaultSlotWidth,
            borderRadius: AppRadius.lgRadius,
          ),
          SizedBox(height: AppSpacing.xl),
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
        ],
      ),
    );
  }
}

class _MyProfileForm extends ConsumerStatefulWidget {
  const _MyProfileForm({
    required this.bottomInset,
    required this.focusPhotos,
  });

  final double bottomInset;
  final bool focusPhotos;

  @override
  ConsumerState<_MyProfileForm> createState() => _MyProfileFormState();
}

class _MyProfileFormState extends ConsumerState<_MyProfileForm> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _city;
  late final TextEditingController _profession;
  late final TextEditingController _bio;
  late final TextEditingController _whyMarriage;
  final _picker = ImagePicker();
  var _seeded = false;
  var _promptedPhoto = false;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController();
    _last = TextEditingController();
    _city = TextEditingController();
    _profession = TextEditingController();
    _bio = TextEditingController();
    _whyMarriage = TextEditingController();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _city.dispose();
    _profession.dispose();
    _bio.dispose();
    _whyMarriage.dispose();
    super.dispose();
  }

  void _seedIfNeeded() {
    final profile = ref.read(myProfileControllerProvider).profile;
    if (profile == null || _seeded) return;
    _seeded = true;
    _first.text = profile.firstName;
    _last.text = profile.lastName;
    _city.text = profile.city;
    _profession.text = profile.profession;
    _bio.text = profile.bio;
    _whyMarriage.text = profile.whyMarriage;
  }

  void _maybePromptPhoto(MyProfileController notifier) {
    if (!widget.focusPhotos || _promptedPhoto) return;
    final profile = ref.read(myProfileControllerProvider).profile;
    if (profile == null || profile.isVerified || profile.photos.isNotEmpty) {
      return;
    }
    _promptedPhoto = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSourceSheet(context, notifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    _seedIfNeeded();
    final state = ref.watch(myProfileControllerProvider);
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();
    final notifier = ref.read(myProfileControllerProvider.notifier);
    _maybePromptPhoto(notifier);
    final colors = context.colors;
    final typography = context.typography;
    final maritalId = maritalStatusToOnboardingId(profile.maritalStatusDb);
    final needsPhoto = !profile.isVerified && profile.photos.isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Photos', style: typography.label),
              const SizedBox(height: AppSpacing.sm),
              Text(
                profile.isVerified
                    ? 'Tes photos sont verrouillées après vérification.'
                    : needsPhoto
                    ? 'Ajoute une photo nette de ton visage pour compléter ton profil.'
                    : 'Tu peux en ajouter jusqu\'à ${myProfilePhotoQuota(isPremium: profile.isPremium)}.',
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MyProfilePhotoGrid(
                photos: profile.photos,
                readOnly: profile.isVerified,
                maxSlots: myProfilePhotoQuota(isPremium: profile.isPremium),
                emphasizeEmpty: widget.focusPhotos || needsPhoto,
                onAdd: () => _openSourceSheet(context, notifier),
                onRemoveAt: notifier.removePhotoAt,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Non modifiables après validation',
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSettingsGroup(
                padding: EdgeInsets.zero,
                children: [
                  AppSettingsRow(
                    label: 'Genre',
                    subtitle: profile.genderLabel ?? 'Non renseigné',
                    icon: Icons.wc_outlined,
                    showChevron: false,
                    onTap: () {},
                  ),
                  AppSettingsRow(
                    label: 'Âge',
                    subtitle: profile.birthDateLabel ?? 'Non renseigné',
                    icon: Icons.cake_outlined,
                    showChevron: false,
                    onTap: () {},
                  ),
                  AppSettingsRow(
                    label: 'Pays',
                    subtitle: profile.country?.trim().isNotEmpty == true
                        ? profile.country
                        : 'Non renseigné',
                    icon: Icons.public_outlined,
                    showChevron: false,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Prénom',
                controller: _first,
                textInputAction: TextInputAction.next,
                onChanged: (value) =>
                    notifier.updateProfile((p) => p.copyWith(firstName: value)),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nom',
                controller: _last,
                textInputAction: TextInputAction.next,
                onChanged: (value) =>
                    notifier.updateProfile((p) => p.copyWith(lastName: value)),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Ville',
                controller: _city,
                textInputAction: TextInputAction.next,
                onChanged: (value) =>
                    notifier.updateProfile((p) => p.copyWith(city: value)),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Profession',
                controller: _profession,
                textInputAction: TextInputAction.next,
                onChanged: (value) => notifier.updateProfile(
                  (p) => p.copyWith(profession: value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Bio',
                controller: _bio,
                maxLines: 5,
                minLines: 4,
                maxLength: 600,
                keyboardType: TextInputType.multiline,
                onChanged: (value) =>
                    notifier.updateProfile((p) => p.copyWith(bio: value)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${profile.bio.length}/600',
                  style: typography.bodySmall,
                ),
              ),
              if (profile.relocateAvailable)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Prêt à déménager', style: typography.bodyLarge),
                  value: profile.willingToRelocate,
                  activeThumbColor: colors.primary,
                  onChanged: (value) => notifier.updateProfile(
                    (p) => p.copyWith(willingToRelocate: value),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Text('Foi', style: typography.label),
              const SizedBox(height: AppSpacing.md),
              AppSelectField(
                label: 'Confession chrétienne',
                sheetTitle: 'Confession chrétienne',
                options: churchDenominations,
                value: profile.denomination.trim().isEmpty
                    ? null
                    : profile.denomination,
                onChanged: (value) => notifier.updateProfile(
                  (p) => p.copyWith(denomination: value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Situation matrimoniale', style: typography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              AppOptionRows(
                items: onboardingMaritalItems(),
                selectedId: maritalId,
                onSelected: (id) {
                  final db = maritalStatusFromOnboardingId(id);
                  if (db == null) return;
                  notifier.updateProfile(
                    (p) => p.copyWith(maritalStatusDb: db),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Pourquoi cherches-tu le mariage ?',
                controller: _whyMarriage,
                maxLines: 4,
                minLines: 3,
                maxLength: FaithDetails.maxWhyMarriage,
                keyboardType: TextInputType.multiline,
                onChanged: (value) => notifier.updateProfile(
                  (p) => p.copyWith(whyMarriage: value),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FaithPage(),
                      ),
                    );
                  },
                  child: const Text('Plus de détails dans Ma Foi'),
                ),
              ),
              if (state.saveError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.saveError!,
                  style: typography.bodySmall.copyWith(color: colors.error),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg + widget.bottomInset,
          ),
          child: AppButton(
            label: 'Enregistrer',
            isLoading: state.isSaving,
            onPressed: () => _save(context, notifier),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, MyProfileController notifier) async {
    final ok = await notifier.save();
    if (!ok || !context.mounted) return;
    ref.invalidate(profileFieldsProvider);
    await ref.read(profileHubControllerProvider.notifier).loadInitial();
    if (!context.mounted) return;
    AppToast.show(context, 'Profil enregistré.', isError: false);
    Navigator.of(context).pop();
  }

  Future<void> _openSourceSheet(
    BuildContext context,
    MyProfileController notifier,
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
    if (source == null || !context.mounted) return;
    final file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    final croppedPath = await cropProfileImage(file.path);
    if (croppedPath == null || !context.mounted) return;
    notifier.addLocalPhoto(croppedPath);
  }
}
