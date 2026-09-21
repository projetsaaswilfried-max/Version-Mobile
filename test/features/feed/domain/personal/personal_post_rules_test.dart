import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/features/feed/domain/entities/personal_post_media.dart';
import 'package:agapeo/features/feed/domain/personal/personal_post_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects more than 600 characters', () {
    final error = PersonalPostRules.validate(body: 'x' * 601);
    expect(error, isA<ValidationFailure>());
    expect(error!.message, '600 caractères maximum.');
  });

  test('accepts 600 characters of text', () {
    expect(PersonalPostRules.validate(body: 'x' * 600), isNull);
  });

  test('rejects empty text without media', () {
    expect(PersonalPostRules.validate(body: '   '), isA<ValidationFailure>());
  });

  test('rejects image heavier than 15 Mo', () {
    final error = PersonalPostRules.validate(
      body: 'ok',
      media: const PersonalPostMedia(
        localPath: '/tmp/a.jpg',
        byteSize: 15 * 1024 * 1024 + 1,
        isVideo: false,
      ),
    );
    expect(error, isA<ValidationFailure>());
  });

  test('allows video without the 15 Mo image cap', () {
    expect(
      PersonalPostRules.validate(
        body: '',
        media: const PersonalPostMedia(
          localPath: '/tmp/a.mp4',
          byteSize: 20 * 1024 * 1024,
          isVideo: true,
        ),
      ),
      isNull,
    );
  });
}
