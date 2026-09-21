import 'package:agapeo/features/discover/domain/entities/discover_profile.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/filtering/filter_discover_profiles.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:flutter_test/flutter_test.dart';

DiscoverProfile _profile({
  required String id,
  String displayName = 'Léa Martin',
  String? city = 'Paris',
  String? confession,
}) {
  return DiscoverProfile(
    id: id,
    displayName: displayName,
    city: city,
    traits: CompatibilityTraits(confession: confession),
  );
}

void main() {
  test('DiscoverQuery is empty when all fields are null or blank', () {
    expect(const DiscoverQuery().isEmpty, isTrue);
    expect(const DiscoverQuery(search: '  ', city: '\n').isEmpty, isTrue);
    expect(const DiscoverQuery().hasSheetFilters, isFalse);
    expect(const DiscoverQuery().hasActiveConstraints, isFalse);
  });

  test('DiscoverQuery is not empty when any field is set', () {
    expect(const DiscoverQuery(search: 'léa').isEmpty, isFalse);
    expect(const DiscoverQuery(city: 'Lyon').isEmpty, isFalse);
    expect(const DiscoverQuery(denomination: 'catho').isEmpty, isFalse);
    expect(const DiscoverQuery(profession: 'médecin').isEmpty, isFalse);
    expect(const DiscoverQuery(city: 'Lyon').hasSheetFilters, isTrue);
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

  test('city filter matches city case-insensitive contains', () {
    final list = [
      _profile(id: '1', city: 'Paris'),
      _profile(id: '2', city: 'Marseille'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(city: 'PAR'),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('denomination filter matches traits.confession', () {
    final list = [
      _profile(id: '1', confession: 'Catholique'),
      _profile(id: '2', confession: 'Protestant'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(denomination: 'catho'),
    );
    expect(filtered.map((p) => p.id), ['1']);
  });

  test('profession is ignored because it is not on DiscoverProfile', () {
    final list = [
      _profile(id: '1', displayName: 'Léa'),
      _profile(id: '2', displayName: 'Naomie'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(profession: 'médecin'),
    );
    expect(filtered, list);
  });

  test('combines search and city with AND', () {
    final list = [
      _profile(id: '1', displayName: 'Léa Martin', city: 'Paris'),
      _profile(id: '2', displayName: 'Léa Durand', city: 'Lyon'),
    ];
    final filtered = filterDiscoverProfiles(
      list,
      const DiscoverQuery(search: 'léa', city: 'lyon'),
    );
    expect(filtered.map((p) => p.id), ['2']);
  });
}
