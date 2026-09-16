import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.fieldErrors = const {},
    this.formError,
    this.succeeded = false,
    this.emailNotConfirmed = false,
  });

  final String email;
  final String password;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final String? formError;
  final bool succeeded;

  /// True when the last attempt failed because the signup OTP/link was
  /// never confirmed — drives a CTA back to the OTP screen instead of a
  /// dead-end error (the member can't otherwise get back there).
  final bool emailNotConfirmed;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    Map<String, String>? fieldErrors,
    Object? formError = _unset,
    bool? succeeded,
    bool? emailNotConfirmed,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: identical(formError, _unset)
          ? this.formError
          : formError as String?,
      succeeded: succeeded ?? this.succeeded,
      emailNotConfirmed: emailNotConfirmed ?? this.emailNotConfirmed,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    isLoading,
    fieldErrors,
    formError,
    succeeded,
    emailNotConfirmed,
  ];
}

const Object _unset = Object();
