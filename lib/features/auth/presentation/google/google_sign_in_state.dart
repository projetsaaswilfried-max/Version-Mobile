import 'package:equatable/equatable.dart';

/// Tracks only the local loading/error state of launching Google OAuth.
/// Navigation on success is NOT this controller's job — see
/// [GoogleSignInController] for why.
class GoogleSignInState extends Equatable {
  const GoogleSignInState({this.isLoading = false, this.formError});

  final bool isLoading;
  final String? formError;

  GoogleSignInState copyWith({
    bool? isLoading,
    String? formError,
    bool clearFormError = false,
  }) {
    return GoogleSignInState(
      isLoading: isLoading ?? this.isLoading,
      formError: clearFormError ? null : (formError ?? this.formError),
    );
  }

  @override
  List<Object?> get props => [isLoading, formError];
}
