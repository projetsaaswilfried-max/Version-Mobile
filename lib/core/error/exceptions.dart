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

class ValidationException implements Exception {
  const ValidationException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Erreur de stockage local.']);

  final String message;
}
