/// Thrown by `data/datasources` on failure, caught and mapped to a
/// [Failure] by the repository implementation. Never leaks past `data/`.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Pas de connexion internet.']);

  final String message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Session expirée.']);

  final String message;
}

/// Login attempted before the signup OTP/link was confirmed. Distinct from
/// [UnauthorizedException] so the UI can offer a way back to the OTP screen
/// instead of just showing an error the member can't act on.
class EmailNotConfirmedException implements Exception {
  const EmailNotConfirmedException([this.message = 'Email non confirmé.']);

  final String message;
}

class ValidationException implements Exception {
  const ValidationException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Erreur de stockage local.']);

  final String message;
}
