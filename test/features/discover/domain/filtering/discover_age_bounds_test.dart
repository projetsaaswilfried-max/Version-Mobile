import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/domain/filtering/discover_age_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 22);

  test('bornOnOrBefore ageMin 28 is today minus 28 years', () {
    expect(
      DiscoverAgeBounds.bornOnOrBefore(28, now),
      DateTime(1998, 9, 22),
    );
  });

  test('bornOnOrAfter ageMax 48 excludes people who already turned 49', () {
    expect(
      DiscoverAgeBounds.bornOnOrAfter(48, now),
      DateTime(1977, 9, 23),
    );
  });

  test('iso helpers skip the full default age range', () {
    const query = DiscoverQuery(
      ageMin: DiscoverQuery.minAge,
      ageMax: DiscoverQuery.maxAge,
    );
    expect(DiscoverAgeBounds.isoBornOnOrBefore(query, now), isNull);
    expect(DiscoverAgeBounds.isoBornOnOrAfter(query, now), isNull);
  });

  test('iso helpers format constrained bounds as yyyy-MM-dd', () {
    const query = DiscoverQuery(ageMin: 28, ageMax: 48);
    expect(DiscoverAgeBounds.isoBornOnOrBefore(query, now), '1998-09-22');
    expect(DiscoverAgeBounds.isoBornOnOrAfter(query, now), '1977-09-23');
  });
}
