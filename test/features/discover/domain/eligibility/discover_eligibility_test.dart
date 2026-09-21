import 'package:agapeo/features/discover/domain/eligibility/discover_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

CandidateEligibility _candidate({
  String id = 'c1',
  String? gender = 'FEMALE',
  bool isStaff = false,
  bool isVerified = true,
  bool isMatched = false,
  bool isComplete = true,
}) {
  return CandidateEligibility(
    id: id,
    gender: gender,
    isStaff: isStaff,
    isVerified: isVerified,
    isMatched: isMatched,
    isComplete: isComplete,
  );
}

void main() {
  test('eligible opposite gender verified complete unmatched non-staff', () {
    expect(
      isDiscoverEligible(visitorGender: 'MALE', candidate: _candidate()),
      isTrue,
    );
    expect(
      isDiscoverEligible(
        visitorGender: 'FEMALE',
        candidate: _candidate(gender: 'MALE'),
      ),
      isTrue,
    );
  });

  test('ineligible when staff', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(isStaff: true),
      ),
      isFalse,
    );
  });

  test('ineligible when already matched', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(isMatched: true),
      ),
      isFalse,
    );
  });

  test('ineligible when same gender', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(gender: 'MALE'),
      ),
      isFalse,
    );
    expect(
      isDiscoverEligible(
        visitorGender: 'FEMALE',
        candidate: _candidate(gender: 'FEMALE'),
      ),
      isFalse,
    );
  });

  test('ineligible when unverified', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(isVerified: false),
      ),
      isFalse,
    );
  });

  test('ineligible when profile incomplete', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(isComplete: false),
      ),
      isFalse,
    );
  });

  test('ineligible when candidate gender is missing or not male/female', () {
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(gender: null),
      ),
      isFalse,
    );
    expect(
      isDiscoverEligible(
        visitorGender: 'MALE',
        candidate: _candidate(gender: 'OTHER'),
      ),
      isFalse,
    );
  });
}
