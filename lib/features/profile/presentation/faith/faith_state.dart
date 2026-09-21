import 'package:equatable/equatable.dart';

import '../../domain/entities/faith_details.dart';

class FaithState extends Equatable {
  const FaithState({
    this.details,
    this.isInitialLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveError,
  });

  final FaithDetails? details;
  final bool isInitialLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveError;

  FaithState copyWith({
    FaithDetails? details,
    bool? isInitialLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveError,
    bool clearError = false,
    bool clearSaveError = false,
  }) {
    return FaithState(
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
