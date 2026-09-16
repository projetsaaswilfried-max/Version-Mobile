import 'package:equatable/equatable.dart';

class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.isLoading = false,
    this.isResending = false,
    this.formError,
    this.succeeded = false,
    this.resendAllowedAt,
  });

  final bool isLoading;
  final bool isResending;
  final String? formError;
  final bool succeeded;
  final DateTime? resendAllowedAt;

  VerifyEmailState copyWith({
    bool? isLoading,
    bool? isResending,
    Object? formError = _unset,
    bool? succeeded,
    Object? resendAllowedAt = _unset,
  }) {
    return VerifyEmailState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
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
    isLoading,
    isResending,
    formError,
    succeeded,
    resendAllowedAt,
  ];
}

const Object _unset = Object();
