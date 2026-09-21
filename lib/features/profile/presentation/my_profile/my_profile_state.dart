import 'package:equatable/equatable.dart';

import '../../domain/entities/my_profile.dart';

class MyProfileState extends Equatable {
  const MyProfileState({
    this.profile,
    this.isInitialLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveError,
  });

  final MyProfile? profile;
  final bool isInitialLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveError;

  MyProfileState copyWith({
    MyProfile? profile,
    bool? isInitialLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveError,
    bool clearError = false,
    bool clearSaveError = false,
    bool clearProfile = false,
  }) {
    return MyProfileState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
    profile,
    isInitialLoading,
    isSaving,
    errorMessage,
    saveError,
  ];
}
