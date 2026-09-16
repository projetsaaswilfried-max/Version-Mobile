import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.fieldErrors = const {},
    this.formError,
    this.successMessage,
  });

  final String email;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final String? formError;
  final String? successMessage;

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    Map<String, String>? fieldErrors,
    Object? formError = _unset,
    Object? successMessage = _unset,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: identical(formError, _unset)
          ? this.formError
          : formError as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    email,
    isLoading,
    fieldErrors,
    formError,
    successMessage,
  ];
}

const Object _unset = Object();
