import 'package:agapeo/features/discover/domain/scoring/compatibility_score.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('perfect twin scores 100', () {
    const twin = CompatibilityTraits(
      confession: 'Évangélique',
      spiritualEngagement: 'active',
      values: ['famille', 'foi'],
      hobbies: ['marche', 'lecture'],
      country: 'FR',
      acceptedCountries: ['BE'],
      age: 30,
      acceptedAgeMin: 25,
      acceptedAgeMax: 40,
      maritalStatus: 'SINGLE_NO_CHILDREN',
      acceptedMarital: ['SINGLE_NO_CHILDREN', 'WIDOWED'],
    );

    expect(compatibilityScore(visitor: twin, candidate: twin), 100);
  });

  test('empty traits score 0', () {
    const empty = CompatibilityTraits();
    expect(compatibilityScore(visitor: empty, candidate: empty), 0);
  });

  test('awards 12 only when confession matches and is set', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(confession: 'Catholique'),
        candidate: const CompatibilityTraits(confession: 'Catholique'),
      ),
      12,
    );
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(confession: 'Catholique'),
        candidate: const CompatibilityTraits(confession: 'Évangélique'),
      ),
      0,
    );
  });

  test('awards 8 only when spiritual engagement matches and is set', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(spiritualEngagement: 'active'),
        candidate: const CompatibilityTraits(spiritualEngagement: 'active'),
      ),
      8,
    );
  });

  test('values overlap is overlap / max(lengths, 1) * 20 rounded', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(values: ['a', 'b']),
        candidate: const CompatibilityTraits(values: ['b', 'c']),
      ),
      10,
    );
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(values: ['a']),
        candidate: const CompatibilityTraits(values: ['a', 'b', 'c']),
      ),
      7,
    );
  });

  test('hobbies overlap is overlap / max(lengths, 1) * 15 rounded', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(hobbies: ['x']),
        candidate: const CompatibilityTraits(hobbies: ['x', 'y', 'z']),
      ),
      5,
    );
  });

  test('same country scores 15 over accepted-country 8', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          country: 'FR',
          acceptedCountries: ['BE'],
        ),
        candidate: const CompatibilityTraits(
          country: 'FR',
          acceptedCountries: ['DE'],
        ),
      ),
      15,
    );
  });

  test('accepted country in either direction scores 8', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          country: 'FR',
          acceptedCountries: ['BE'],
        ),
        candidate: const CompatibilityTraits(country: 'BE'),
      ),
      8,
    );
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(country: 'FR'),
        candidate: const CompatibilityTraits(
          country: 'BE',
          acceptedCountries: ['FR'],
        ),
      ),
      8,
    );
  });

  test('age scores 10 both ways and 5 one way', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          age: 30,
          acceptedAgeMin: 25,
          acceptedAgeMax: 40,
        ),
        candidate: const CompatibilityTraits(
          age: 32,
          acceptedAgeMin: 28,
          acceptedAgeMax: 35,
        ),
      ),
      10,
    );
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          age: 30,
          acceptedAgeMin: 25,
          acceptedAgeMax: 40,
        ),
        candidate: const CompatibilityTraits(
          age: 50,
          acceptedAgeMin: 28,
          acceptedAgeMax: 35,
        ),
      ),
      5,
    );
  });

  test('marital scores 20 both ways and 10 one way without filtering', () {
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          maritalStatus: 'SINGLE_NO_CHILDREN',
          acceptedMarital: ['DIVORCED'],
        ),
        candidate: const CompatibilityTraits(
          maritalStatus: 'DIVORCED',
          acceptedMarital: ['SINGLE_NO_CHILDREN'],
        ),
      ),
      20,
    );
    expect(
      compatibilityScore(
        visitor: const CompatibilityTraits(
          maritalStatus: 'SINGLE_NO_CHILDREN',
          acceptedMarital: ['DIVORCED'],
        ),
        candidate: const CompatibilityTraits(
          maritalStatus: 'DIVORCED',
          acceptedMarital: ['WIDOWED'],
        ),
      ),
      10,
    );
  });
}
