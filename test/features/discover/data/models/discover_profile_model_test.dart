import 'package:agapeo/features/discover/data/models/discover_profile_model.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:flutter_test/flutter_test.dart';

const _traits = CompatibilityTraits();

Map<String, dynamic> _row({
  String? id = 'p1',
  String firstName = 'Léa',
  String lastName = 'Martin',
  String? photoUrl,
  Object? photos,
  String verification = 'VERIFIED',
  String gender = 'FEMALE',
  String birthDate = '1998-03-10',
  String city = 'Paris',
  String country = 'FR',
  bool isStaff = false,
  bool isMatched = false,
  String confession = 'protestant',
  String whyMarriage = 'Pour construire',
}) {
  return {
    if (id != null) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (photos != null) 'profile_photos': photos,
    'photo_verification_status': verification,
    'gender': gender,
    'birth_date': birthDate,
    'city': city,
    'country': country,
    'is_staff': isStaff,
    'is_matched': isMatched,
    'church_denomination': confession,
    'why_marriage': whyMarriage,
  };
}

void main() {
  final now = DateTime.utc(2026, 9, 18);

  test('parses name, http avatar and verified badge', () {
    final profile = DiscoverProfileModel.fromJson(
      _row(photoUrl: 'https://cdn.example/lea.jpg'),
      visitorTraits: _traits,
      revealIdentity: false,
      now: () => now,
    );

    expect(profile, isNotNull);
    expect(profile!.id, 'p1');
    expect(profile.displayName, 'Léa Martin');
    expect(profile.photoUrl, 'https://cdn.example/lea.jpg');
    expect(profile.isVerified, isTrue);
    expect(profile.city, 'Paris');
    expect(profile.age, 28);
    expect(profile.gender, 'FEMALE');
    expect(profile.isComplete, isTrue);
    expect(profile.traits.confession, 'protestant');
    expect(profile.traits.country, 'FR');
  });

  test('keeps raw identity even when revealIdentity is false', () {
    final profile = DiscoverProfileModel.fromJson(
      _row(),
      visitorTraits: _traits,
      revealIdentity: false,
      now: () => now,
    );

    expect(profile!.displayName, 'Léa Martin');
    expect(profile.city, 'Paris');
    expect(profile.age, 28);
    expect(profile.ageLabel, isNull);
  });

  test('ignores storage-path photos until datasource hydrates http', () {
    final profile = DiscoverProfileModel.fromJson(
      _row(
        photos: [
          {'storage_path': 'uuid/slot_0.jpg', 'is_primary': true},
        ],
      ),
      visitorTraits: _traits,
      revealIdentity: true,
      now: () => now,
    );
    expect(profile!.photoUrl, isNull);
    // La présence d'une entrée photo suffit pour la complétude §7.
    expect(profile.isComplete, isTrue);
  });

  test('picks primary photo http url from embed', () {
    final profile = DiscoverProfileModel.fromJson(
      _row(
        photos: [
          {'url': 'https://cdn.example/other.jpg', 'is_primary': false},
          {'url': 'https://cdn.example/primary.jpg', 'is_primary': true},
        ],
      ),
      visitorTraits: _traits,
      revealIdentity: true,
      now: () => now,
    );
    expect(profile!.photoUrl, 'https://cdn.example/primary.jpg');
  });

  test('skips row without id', () {
    expect(
      DiscoverProfileModel.fromJson(
        _row(id: null),
        visitorTraits: _traits,
        revealIdentity: true,
      ),
      isNull,
    );
  });

  test(
    'isVerified is false when photo_verification_status is not VERIFIED',
    () {
      final profile = DiscoverProfileModel.fromJson(
        _row(verification: 'PENDING'),
        visitorTraits: _traits,
        revealIdentity: true,
      );
      expect(profile!.isVerified, isFalse);
    },
  );

  test('isComplete is false when a S02 field is missing', () {
    final profile = DiscoverProfileModel.fromJson(
      _row(whyMarriage: ''),
      visitorTraits: _traits,
      revealIdentity: true,
    );
    expect(profile!.isComplete, isFalse);
  });
}
