import 'package:agapeo/features/profile/domain/mapping/marital_status_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maritalStatusToOnboardingId maps DB enums', () {
    expect(maritalStatusToOnboardingId('SINGLE_NO_CHILDREN'), 'single');
    expect(maritalStatusToOnboardingId('SINGLE'), 'single');
    expect(
      maritalStatusToOnboardingId('SINGLE_WITH_CHILDREN'),
      'singleWithChildren',
    );
    expect(maritalStatusToOnboardingId('DIVORCED'), 'divorced');
    expect(maritalStatusToOnboardingId('WIDOWED'), 'widowed');
    expect(maritalStatusToOnboardingId(null), isNull);
  });

  test('maritalStatusFromOnboardingId maps UI ids to DB', () {
    expect(maritalStatusFromOnboardingId('single'), 'SINGLE_NO_CHILDREN');
    expect(
      maritalStatusFromOnboardingId('singleWithChildren'),
      'SINGLE_WITH_CHILDREN',
    );
    expect(maritalStatusFromOnboardingId('divorced'), 'DIVORCED');
    expect(maritalStatusFromOnboardingId('widowed'), 'WIDOWED');
    expect(maritalStatusFromOnboardingId('nope'), isNull);
  });
}
