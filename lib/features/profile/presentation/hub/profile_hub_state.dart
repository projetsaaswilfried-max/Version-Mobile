import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_hub.dart';

class ProfileHubState extends Equatable {
  const ProfileHubState({
    this.hub,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final ProfileHub? hub;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  ProfileHubState copyWith({
    ProfileHub? hub,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    bool clearHub = false,
  }) {
    return ProfileHubState(
      hub: clearHub ? null : (hub ?? this.hub),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    hub,
    isInitialLoading,
    isRefreshing,
    errorMessage,
  ];
}
