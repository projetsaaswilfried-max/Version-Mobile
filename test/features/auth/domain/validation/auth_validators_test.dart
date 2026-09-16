import 'package:agapeo/features/auth/domain/validation/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejects empty', () {
      expect(AuthValidators.email(''), isNotNull);
    });
    test('rejects invalid', () {
      expect(AuthValidators.email('pas-un-email'), isNotNull);
    });
    test('accepts valid', () {
      expect(AuthValidators.email('a@b.co'), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('rejects short', () {
      expect(AuthValidators.password('Ab1'), isNotNull);
    });
    test('rejects no digit', () {
      expect(AuthValidators.password('Abcdefgh'), isNotNull);
    });
    test('rejects no letter', () {
      expect(AuthValidators.password('12345678'), isNotNull);
    });
    test('accepts valid', () {
      expect(AuthValidators.password('Abcdefg1'), isNull);
    });
  });

  group('AuthValidators.otp', () {
    test('requires exactly 6 digits', () {
      expect(AuthValidators.otp('12345'), isNotNull);
      expect(AuthValidators.otp('1234567'), isNotNull);
      expect(AuthValidators.otp('12ab56'), isNotNull);
      expect(AuthValidators.otp('123456'), isNull);
    });
  });
}
