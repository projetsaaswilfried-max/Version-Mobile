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
}

class SocketExceptionMessage {
  const SocketExceptionMessage();

  @override
  String toString() => 'SocketException: Failed host lookup';
}
