import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/user_facing_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps clear French Failure message', () {
    expect(
      userFacingMessage(const NetworkFailure('Pas de connexion internet.')),
      'Pas de connexion internet.',
    );
    expect(
      userFacingMessage(const ValidationFailure('Mot de passe trop court.')),
      'Mot de passe trop court.',
    );
  });

  test('softens empty and technical messages', () {
    expect(
      userFacingMessage(const ServerFailure('')),
      'Une erreur serveur est survenue.',
    );
    expect(
      userFacingMessage(const ServerFailure('PGRST116: JSON object requested')),
      'Une erreur serveur est survenue.',
    );
    expect(
      userFacingMessageFromRaw('AuthRetryableFetchException: Failed'),
      "Une erreur inattendue est survenue.",
    );
  });
}
