import 'package:agapeo/features/discover/data/models/discover_profile_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  String? id = 'p1',
  String firstName = 'Léa',
  String lastName = 'Martin',
  String? photoUrl,
  String? avatarUrl,
  Object? photos,
  String verification = 'VERIFIED',
  String birthDate = '1998-03-10',
  String city = 'Paris',
  String confession = 'protestant',
  String spiritual = 'pratique',
  String whyMarriage = 'Pour construire',
  Object? values = const ['foi', 'famille'],
  Object? hobbies = const ['course', 'lecture'],
}) {
  return {
    if (id != null) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (photos != null) 'profile_photos': photos,
    'photo_verification_status': verification,
    'birth_date': birthDate,
    'city': city,
    'church_denomination': confession,
    'spiritual_engagement': spiritual,
    'why_marriage': whyMarriage,
    'values': values,
    'hobbies': hobbies,
  };
}

void main() {
  final now = DateTime.utc(2026, 9, 18);

  test('parses identity, bio lists and verified badge', () {
    final detail = DiscoverProfileDetailModel.fromJson(_row(), now: () => now);

    expect(detail, isNotNull);
    expect(detail!.id, 'p1');
    expect(detail.displayName, 'Léa Martin');
    expect(detail.age, 28);
    expect(detail.city, 'Paris');
    expect(detail.isVerified, isTrue);
    expect(detail.score, 0);
    expect(detail.confession, 'protestant');
    expect(detail.spiritualEngagement, 'pratique');
    expect(detail.whyMarriage, 'Pour construire');
    expect(detail.values, ['foi', 'famille']);
    expect(detail.hobbies, ['course', 'lecture']);
  });

  test('collects every hydrated http photo, primary first', () {
    final detail = DiscoverProfileDetailModel.fromJson(
      _row(
        photos: [
          {'url': 'https://cdn.example/other.jpg', 'is_primary': false},
          {'url': 'https://cdn.example/primary.jpg', 'is_primary': true},
          {'url': 'https://cdn.example/third.jpg', 'is_primary': false},
        ],
      ),
      now: () => now,
    );

    expect(detail!.photoUrls, [
      'https://cdn.example/primary.jpg',
      'https://cdn.example/other.jpg',
      'https://cdn.example/third.jpg',
    ]);
  });

  test('includes top-level http photo_url without duplicating embed', () {
    final detail = DiscoverProfileDetailModel.fromJson(
      _row(
        photoUrl: 'https://cdn.example/primary.jpg',
        photos: [
          {'url': 'https://cdn.example/primary.jpg', 'is_primary': true},
          {'url': 'https://cdn.example/other.jpg', 'is_primary': false},
        ],
      ),
      now: () => now,
    );

    expect(detail!.photoUrls, [
      'https://cdn.example/primary.jpg',
      'https://cdn.example/other.jpg',
    ]);
  });

  test('ignores storage-path photos until datasource hydrates http', () {
    final detail = DiscoverProfileDetailModel.fromJson(
      _row(
        photos: [
          {'storage_path': 'uuid/slot_0.jpg', 'is_primary': true},
        ],
      ),
      now: () => now,
    );

    expect(detail!.photoUrls, isEmpty);
  });

  test('skips row without id', () {
    expect(
      DiscoverProfileDetailModel.fromJson(_row(id: null), now: () => now),
      isNull,
    );
  });
}
