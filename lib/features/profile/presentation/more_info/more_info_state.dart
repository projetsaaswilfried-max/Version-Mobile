import 'package:equatable/equatable.dart';

import '../../domain/entities/more_info_details.dart';

class MoreInfoState extends Equatable {
  const MoreInfoState({
    this.details,
    this.isInitialLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveError,
  });

  final MoreInfoDetails? details;
  final bool isInitialLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveError;

  MoreInfoState copyWith({
    MoreInfoDetails? details,
    bool? isInitialLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveError,
    bool clearError = false,
    bool clearSaveError = false,
  }) {
    return MoreInfoState(
      details: details ?? this.details,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
    details,
    isInitialLoading,
    isSaving,
    errorMessage,
    saveError,
  ];
}
