import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/entities/my_profile_photo.dart';
import '../../domain/photo_quota.dart';
import 'my_profile_state.dart';

class MyProfileController extends Notifier<MyProfileState> {
  int maxPhotosFor(MyProfile profile) =>
      myProfilePhotoQuota(isPremium: profile.isPremium);

  @override
  MyProfileState build() {
    Future<void>.microtask(loadInitial);
    return const MyProfileState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      clearSaveError: true,
      clearProfile: true,
    );
    final result = await ref.read(getMyProfileProvider)();
    if (!ref.mounted) return;
    switch (result) {
      case Ok<MyProfile>(:final value):
        state = state.copyWith(
          profile: value,
          isInitialLoading: false,
          clearError: true,
        );
      case Err<MyProfile>(:final failure):
        state = state.copyWith(
          isInitialLoading: false,
          clearProfile: true,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> retry() => loadInitial();

  void updateProfile(MyProfile Function(MyProfile current) update) {
    final current = state.profile;
    if (current == null) return;
    state = state.copyWith(profile: update(current), clearSaveError: true);
  }

  void addLocalPhoto(String localPath) {
    final current = state.profile;
    if (current == null || current.isVerified) return;
    if (current.photos.length >= maxPhotosFor(current)) return;
    state = state.copyWith(
      profile: current.copyWith(
        photos: [
          ...current.photos,
          MyProfilePhoto(localPath: localPath),
        ],
      ),
    );
  }

  void removePhotoAt(int index) {
    final current = state.profile;
    if (current == null || current.isVerified) return;
    if (index < 0 || index >= current.photos.length) return;
    final next = [...current.photos]..removeAt(index);
    state = state.copyWith(profile: current.copyWith(photos: next));
  }

  Future<bool> save() async {
    final current = state.profile;
    if (current == null) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);
    final result = await ref.read(saveMyProfileProvider)(current);
    if (!ref.mounted) return false;
    switch (result) {
      case Ok<void>():
        state = state.copyWith(isSaving: false, clearSaveError: true);
        return true;
      case Err<void>(:final failure):
        state = state.copyWith(isSaving: false, saveError: failure.message);
        return false;
    }
  }
}

final myProfileControllerProvider =
    NotifierProvider.autoDispose<MyProfileController, MyProfileState>(
      MyProfileController.new,
    );
