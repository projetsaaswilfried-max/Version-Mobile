import 'package:equatable/equatable.dart';

/// Domain-facing error, returned by usecases/repositories — never a raw
/// exception. Data-layer [Exception]s are mapped to a [Failure] at the
/// repository boundary.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur serveur est survenue.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expirée.']);
}

/// Login attempted before the signup OTP/link was confirmed. Distinct from
/// [UnauthorizedFailure] so the UI can offer a way back to the OTP screen.
class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure([super.message = 'Email non confirmé.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de stockage local.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = "Une erreur inattendue est survenue."]);
}
