import 'exceptions.dart';
import 'failure.dart';

Failure mapDataException(Object error) {
  return switch (error) {
    EmailNotConfirmedException(:final message) => EmailNotConfirmedFailure(
      message,
    ),
    UnauthorizedException(:final message) => UnauthorizedFailure(message),
    NetworkException(:final message) => NetworkFailure(message),
    ValidationException(:final message, :final fieldErrors) =>
      ValidationFailure(message, fieldErrors: fieldErrors),
    ServerException(:final message) => ServerFailure(message),
    _ => UnknownFailure(error.toString()),
  };
}
