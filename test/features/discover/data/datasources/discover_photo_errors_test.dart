import 'package:agapeo/features/discover/data/datasources/discover_photo_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('swallows oversized URL or payload errors', () {
    expect(
      isOversizedPhotoChunkError(message: 'Request URI too long', code: '414'),
      isTrue,
    );
    expect(
      isOversizedPhotoChunkError(message: 'payload too large', code: '413'),
      isTrue,
    );
  });

  test('does not swallow RLS or expired session', () {
    expect(
      isOversizedPhotoChunkError(
        message: 'permission denied for table profile_photos',
        code: '42501',
      ),
      isFalse,
    );
    expect(
      isOversizedPhotoChunkError(message: 'JWT expired', code: 'PGRST301'),
      isFalse,
    );
  });
}
