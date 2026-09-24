import 'package:equatable/equatable.dart';

class AppleSignInState extends Equatable {
  const AppleSignInState({
    this.isLoading = false,
    this.formError,
    this.succeeded = false,
    this.email = '',
  });

  final bool isLoading;
  final String? formError;
  final bool succeeded;
  final String email;

  AppleSignInState copyWith({
    bool? isLoading,
    String? formError,
    bool clearFormError = false,
    bool? succeeded,
    String? email,
  }) {
    return AppleSignInState(
      isLoading: isLoading ?? this.isLoading,
      formError: clearFormError ? null : (formError ?? this.formError),
      succeeded: succeeded ?? this.succeeded,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [isLoading, formError, succeeded, email];
}
