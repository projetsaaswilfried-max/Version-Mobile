import 'package:agapeo/features/profile/domain/mapping/marital_status_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps PRD marital_status_type values to French labels', () {
    expect(maritalStatusLabel('SINGLE_NO_CHILDREN'), 'Célibataire sans enfant');
    expect(
      maritalStatusLabel('SINGLE_WITH_CHILDREN'),
      'Célibataire avec enfant(s)',
    );
    expect(maritalStatusLabel('DIVORCED'), 'Divorcé(e)');
    expect(maritalStatusLabel('WIDOWED'), 'Veuf / veuve');
  });

  test('is case-insensitive and hides unknown enums', () {
    expect(maritalStatusLabel('divorced'), 'Divorcé(e)');
    expect(maritalStatusLabel('MARRY_WITH_CHILDREN'), isNull);
    expect(maritalStatusLabel('  '), isNull);
    expect(maritalStatusLabel(null), isNull);
  });
}
