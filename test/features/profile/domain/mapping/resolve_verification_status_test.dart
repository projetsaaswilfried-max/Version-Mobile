import 'package:agapeo/features/profile/domain/mapping/resolve_verification_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no verification_requests row - falls back to profiles', () {
    expect(
      resolveVerificationStatus(requestStatus: null, profileStatus: 'UNVERIFIED'),
      'UNVERIFIED',
    );
  });

  test('PENDING/REJECTED from verification_requests always wins', () {
    expect(
      resolveVerificationStatus(requestStatus: 'PENDING', profileStatus: 'VERIFIED'),
      'PENDING',
    );
    expect(
      resolveVerificationStatus(requestStatus: 'REJECTED', profileStatus: 'VERIFIED'),
      'REJECTED',
    );
  });

  test('VERIFIED agreed by both sources - VERIFIED', () {
    expect(
      resolveVerificationStatus(requestStatus: 'VERIFIED', profileStatus: 'VERIFIED'),
      'VERIFIED',
    );
  });

  test(
    'VERIFIED request but profiles reset (primary photo deleted) - defers to profiles',
    () {
      expect(
        resolveVerificationStatus(
          requestStatus: 'VERIFIED',
          profileStatus: 'UNVERIFIED',
        ),
        'UNVERIFIED',
      );
    },
  );

  test('case-insensitive comparison', () {
    expect(
      resolveVerificationStatus(requestStatus: 'verified', profileStatus: 'VERIFIED'),
      'verified',
    );
  });
}
