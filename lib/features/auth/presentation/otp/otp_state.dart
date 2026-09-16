import 'package:equatable/equatable.dart';

class OtpState extends Equatable {
  const OtpState({
    this.otp = '',
    this.isLoading = false,
    this.isResending = false,
    this.fieldErrors = const {},
    this.formError,
    this.succeeded = false,
    this.resendAllowedAt,
  });

  final String otp;
  final bool isLoading;
  final bool isResending;
  final Map<String, String> fieldErrors;
  final String? formError;
  final bool succeeded;
  final DateTime? resendAllowedAt;

  OtpState copyWith({
    String? otp,
    bool? isLoading,
    bool? isResending,
    Map<String, String>? fieldErrors,
    Object? formError = _unset,
    bool? succeeded,
    Object? resendAllowedAt = _unset,
  }) {
    return OtpState(
      otp: otp ?? this.otp,
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: identical(formError, _unset)
          ? this.formError
          : formError as String?,
      succeeded: succeeded ?? this.succeeded,
      resendAllowedAt: identical(resendAllowedAt, _unset)
          ? this.resendAllowedAt
          : resendAllowedAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    otp,
    isLoading,
    isResending,
    fieldErrors,
    formError,
    succeeded,
    resendAllowedAt,
  ];
}

const Object _unset = Object();
