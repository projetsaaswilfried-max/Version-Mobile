import 'package:agapeo/core/config/countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding countries cover Africa and diasporas without Autre', () {
    expect(kOnboardingCountries.contains('Autre'), isFalse);
    expect(
      kOnboardingCountries,
      containsAll(['France', 'Côte d\'Ivoire', 'Sénégal']),
    );
    expect(kOnboardingCountries.length, greaterThanOrEqualTo(50));
  });
}
