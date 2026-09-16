import 'package:equatable/equatable.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.password = '',
    this.passwordConfirm = '',
    this.isLoading = false,
    this.fieldErrors = const {},
    this.formError,
    this.succeeded = false,
  });

  final String password;
  final String passwordConfirm;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final String? formError;
  final bool succeeded;

  ResetPasswordState copyWith({
    String? password,
    String? passwordConfirm,
    bool? isLoading,
    Map<String, String>? fieldErrors,
    String? formError,
    bool clearFormError = false,
    bool? succeeded,
  }) {
    return ResetPasswordState(
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      isLoading: isLoading ?? this.isLoading,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: clearFormError ? null : (formError ?? this.formError),
      succeeded: succeeded ?? this.succeeded,
    );
  }

  @override
  List<Object?> get props => [
    password,
    passwordConfirm,
    isLoading,
    fieldErrors,
    formError,
    succeeded,
  ];
}
