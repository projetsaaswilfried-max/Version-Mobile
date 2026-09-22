import 'package:agapeo/features/discover/domain/entities/discover_profile.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/filtering/filter_discover_profiles.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:flutter_test/flutter_test.dart';

DiscoverProfile _profile({
  required String id,
  String displayName = 'Léa Martin',
  String? city = 'Paris',
  int? age = 28,
  String? country,
  String? confession,
  String? maritalStatus,
}) {
  return DiscoverProfile(
    id: id,
    displayName: displayName,
    city: city,
    age: age,
    traits: CompatibilityTraits(
      country: country,
      confession: confession,
      maritalStatus: maritalStatus,
    ),
  );
}

void main() {
  test('DiscoverQuery is empty when all fields are null or blank', () {
    expect(const DiscoverQuery().isEmpty, isTrue);
    expect(const DiscoverQuery(search: '  ', country: '\n').isEmpty, isTrue);
    expect(const DiscoverQuery(ageMin: 18, ageMax: 80).isEmpty, isTrue);
    expect(const DiscoverQuery().hasSheetFilters, isFalse);
    expect(const DiscoverQuery().hasActiveConstraints, isFalse);
  });

  test('DiscoverQuery is not empty when any field is set', () {
    expect(const DiscoverQuery(search: 'léa').isEmpty, isFalse);
    expect(const DiscoverQuery(country: 'France').isEmpty, isFalse);
    expect(
      const DiscoverQuery(denominations: ['Catholique']).isEmpty,
      isFalse,
    );
    expect(
      const DiscoverQuery(maritalStatuses: ['DIVORCED']).isEmpty,
      isFalse,
    );
    expect(const DiscoverQuery(ageMin: 25).isEmpty, isFalse);
    expect(const DiscoverQuery(ageMax: 40).isEmpty, isFalse);
    expect(const DiscoverQuery(country: 'France').hasSheetFilters, isTrue);
    expect(const DiscoverQuery(search: 'léa').hasSheetFilters, isFalse);
    expect(const DiscoverQuery(search: 'léa').hasActiveConstraints, isTrue);
  });

  test('empty query returns the same list', () {
    final list = [_profile(id: '1'), _profile(id: '2', displayName: 'Naomie')];
    expect(filterDiscoverProfiles(list, const DiscoverQuery()), list);
  });

  test('search matches displayName case-insensitive contains', () {
    final list = [
      _profile(id: '1', displayName: 'Léa Martin'),
      _profile(id: '2', displayName: 'Naomie Dupont'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(search: 'LÉA'),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('search matches city case-insensitive contains', () {
    final list = [
      _profile(id: '1', city: 'Paris'),
      _profile(id: '2', city: 'Lyon'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(search: 'yon'),
    );
    expect(filtered.map((p) => p.id), ['2']);
  });

  test('country filter matches traits.country exactly', () {
    final list = [
      _profile(id: '1', country: 'France'),
      _profile(id: '2', country: 'Sénégal'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(country: 'france'),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('denomination filter matches traits.confession exactly', () {
    final list = [
      _profile(id: '1', confession: 'Catholique'),
      _profile(id: '2', confession: 'Protestante'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(denominations: ['Catholique']),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('denomination filter ORs several closed-list values', () {
    final list = [
      _profile(id: '1', confession: 'Catholique'),
      _profile(id: '2', confession: 'Évangélique'),
      _profile(id: '3', confession: 'Baptiste'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(denominations: ['Catholique', 'Baptiste']),
    );
    expect(filtered.map((p) => p.id), ['1', '3']);
  });

  test('marital filter matches traits.maritalStatus', () {
    final list = [
      _profile(id: '1', maritalStatus: 'SINGLE_NO_CHILDREN'),
      _profile(id: '2', maritalStatus: 'DIVORCED'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(maritalStatuses: ['divorced']),
    );
    expect(filtered.map((p) => p.id), ['2']);
  });

  test('age filter keeps profiles inside the inclusive range', () {
    final list = [
      _profile(id: '1', age: 22),
      _profile(id: '2', age: 30),
      _profile(id: '3', age: 48),
      _profile(id: '4', age: 55),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(ageMin: 28, ageMax: 48),
    );
    expect(filtered.map((p) => p.id), ['2', '3']);
  });

  test('age filter drops profiles without an age', () {
    final list = [
      _profile(id: '1', age: 30),
      _profile(id: '2', age: null),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(ageMin: 25),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('combines search and country with AND', () {
    final list = [
      _profile(id: '1', displayName: 'Léa Martin', country: 'France'),
      _profile(id: '2', displayName: 'Léa Durand', country: 'Sénégal'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(search: 'léa', country: 'Sénégal'),
    );
    expect(filtered.map((p) => p.id), ['2']);
  });
}
