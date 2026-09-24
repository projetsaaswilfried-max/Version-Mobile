import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub_section.dart';
import 'package:flutter_test/flutter_test.dart';

ProfileFieldsSnapshot fields({
  String? firstName,
  String? lastName,
  String? photoVerificationStatus,
  String? primaryPhotoUrl,
}) {
  return ProfileFieldsSnapshot(
    hasGender: true,
    hasBirthDate: true,
    hasCountry: true,
    hasPrimaryPhoto: primaryPhotoUrl != null,
    hasFaithConfession: true,
    hasWhyMarriage: true,
    hasMaritalStatus: true,
    hasHobbies: true,
    firstName: firstName,
    lastName: lastName,
    photoVerificationStatus: photoVerificationStatus,
    primaryPhotoUrl: primaryPhotoUrl,
  );
}

void main() {
  test('joins first and last name', () {
    final hub = ProfileHub.fromFields(
      fields(firstName: 'Léa', lastName: 'Martin'),
      fallbackEmail: 'lea@agapeo.love',
    );
    expect(hub.displayName, 'Léa Martin');
    expect(hub.isVerified, isFalse);
    expect(hub.photoUrl, isNull);
  });

  test('falls back to session email when name is blank', () {
    final hub = ProfileHub.fromFields(
      fields(firstName: '  ', lastName: null),
      fallbackEmail: 'lea@agapeo.love',
    );
    expect(hub.displayName, 'lea@agapeo.love');
  });

  test('badge only when VERIFIED', () {
    expect(
      ProfileHub.fromFields(
        fields(photoVerificationStatus: 'verified'),
        fallbackEmail: 'a@b.c',
      ).isVerified,
      isTrue,
    );
    expect(
      ProfileHub.fromFields(
        fields(photoVerificationStatus: 'PENDING'),
        fallbackEmail: 'a@b.c',
      ).isVerified,
      isFalse,
    );
  });

  test('keeps primary photo url or null', () {
    expect(
      ProfileHub.fromFields(
        fields(primaryPhotoUrl: 'https://cdn/p.jpg'),
        fallbackEmail: 'a@b.c',
      ).photoUrl,
      'https://cdn/p.jpg',
    );
    expect(
      ProfileHub.fromFields(fields(), fallbackEmail: 'a@b.c').photoUrl,
      isNull,
    );
  });

  test('exposes the 9 section labels (8 PRD + Mon Plan)', () {
    expect(ProfileHubSection.values.map((s) => s.label).toList(), [
      'Mon Profil',
      'Ma Foi',
      'Plus d\'infos',
      'Mon Plan',
      'Mes Publications',
      'Mes Favoris',
      'Qui s\'intéresse à moi',
      'Confidentialité',
      'Compte & Sécurité',
    ]);
  });
}
