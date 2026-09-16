import 'package:equatable/equatable.dart';

class RegistrationState extends Equatable {
  const RegistrationState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.passwordConfirm = '',
    this.acceptedTerms = false,
    this.acceptedCharter = false,
    this.isLoading = false,
    this.fieldErrors = const {},
    this.formError,
    this.succeeded = false,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String passwordConfirm;
  final bool acceptedTerms;
  final bool acceptedCharter;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final String? formError;
  final bool succeeded;

  RegistrationState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? passwordConfirm,
    bool? acceptedTerms,
    bool? acceptedCharter,
    bool? isLoading,
    Map<String, String>? fieldErrors,
    Object? formError = _unset,
    bool? succeeded,
  }) {
    return RegistrationState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedCharter: acceptedCharter ?? this.acceptedCharter,
      isLoading: isLoading ?? this.isLoading,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: identical(formError, _unset)
          ? this.formError
          : formError as String?,
      succeeded: succeeded ?? this.succeeded,
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    password,
    passwordConfirm,
    acceptedTerms,
    acceptedCharter,
    isLoading,
    fieldErrors,
    formError,
    succeeded,
  ];
}

const Object _unset = Object();
