import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/supabase_exception_mapping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps auth 401 and jwt to UnauthorizedException', () {
    expect(
      mapSupabaseAuthException(AuthException('jwt expired', statusCode: '401')),
      isA<UnauthorizedException>(),
    );
  });

  test('maps Postgrest RLS codes to UnauthorizedException', () {
    expect(
      mapPostgrestException(
        PostgrestException(message: 'denied', code: '42501'),
      ),
      isA<UnauthorizedException>(),
    );
  });

  test('maps socket-like unknowns to NetworkException', () {
    expect(
      mapUnknownSupabase(const SocketExceptionMessage()),
      isA<NetworkException>(),
    );
  });

  test('passes an already-mapped exception through, keeps its message', () {
    // Un _guard()/try-catch imbriqué (ex. une méthode de datasource qui en
    // appelle une autre déjà gardée) peut faire remonter une exception déjà
    // mappée jusqu'ici - sans ça, e.toString() donnait
    // "Instance of 'ServerException'" au lieu du vrai message.
    const inner = ServerException('Photo de vérification floue.');
    final mapped = mapUnknownSupabase(inner);
    expect(mapped, isA<ServerException>());
    expect((mapped as ServerException).message, 'Photo de vérification floue.');
  });
}

class SocketExceptionMessage {
  const SocketExceptionMessage();

  @override
  String toString() => 'SocketException: Failed host lookup';
}
