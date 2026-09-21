import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/map_data_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps known data exceptions to matching failures', () {
    expect(
      mapDataException(const EmailNotConfirmedException('otp')),
      isA<EmailNotConfirmedFailure>(),
    );
    expect(
      mapDataException(const UnauthorizedException('session')),
      isA<UnauthorizedFailure>(),
    );
    expect(
      mapDataException(const NetworkException('offline')),
      isA<NetworkFailure>(),
    );
    expect(
      mapDataException(const ValidationException('bad')),
      isA<ValidationFailure>(),
    );
    expect(
      mapDataException(const ServerException('boom')),
      isA<ServerFailure>(),
    );
    expect(mapDataException(StateError('x')), isA<UnknownFailure>());
  });
}
