import 'package:equatable/equatable.dart';

class GoogleSignInState extends Equatable {
  const GoogleSignInState({
    this.isLoading = false,
    this.formError,
    this.succeeded = false,
    this.email = '',
  });

  final bool isLoading;
  final String? formError;
  final bool succeeded;
  final String email;

  GoogleSignInState copyWith({
    bool? isLoading,
    String? formError,
    bool clearFormError = false,
    bool? succeeded,
    String? email,
  }) {
    return GoogleSignInState(
      isLoading: isLoading ?? this.isLoading,
      formError: clearFormError ? null : (formError ?? this.formError),
      succeeded: succeeded ?? this.succeeded,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [isLoading, formError, succeeded, email];
}
