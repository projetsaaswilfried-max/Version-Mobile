import 'package:equatable/equatable.dart';

import '../../domain/entities/privacy_settings.dart';

class PrivacyState extends Equatable {
  const PrivacyState({
    this.settings,
    this.isInitialLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveError,
  });

  final PrivacySettings? settings;
  final bool isInitialLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveError;

  PrivacyState copyWith({
    PrivacySettings? settings,
    bool? isInitialLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveError,
    bool clearError = false,
    bool clearSaveError = false,
  }) {
    return PrivacyState(
      settings: settings ?? this.settings,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
    settings,
    isInitialLoading,
    isSaving,
    errorMessage,
    saveError,
  ];
}
