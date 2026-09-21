import 'package:flutter/material.dart';

import '../../../../core/widgets/app_option_item.dart';
import '../../../../core/config/church_denominations.dart';
import 'onboarding_draft.dart';

String onboardingGenderId(OnboardingGender gender) => gender.name;

String onboardingGenderLabel(OnboardingGender gender) {
  switch (gender) {
    case OnboardingGender.woman:
      return 'Femme';
    case OnboardingGender.man:
      return 'Homme';
    case OnboardingGender.other:
      return 'Autre';
  }
}

IconData onboardingGenderIcon(OnboardingGender gender) {
  switch (gender) {
    case OnboardingGender.woman:
      return Icons.woman;
    case OnboardingGender.man:
      return Icons.man;
    case OnboardingGender.other:
      return Icons.transgender;
  }
}

OnboardingGender? onboardingGenderFromId(String id) {
  for (final value in OnboardingGender.values) {
    if (onboardingGenderId(value) == id) return value;
  }
  return null;
}

List<AppOptionItem> onboardingGenderItems() {
  const selectable = [OnboardingGender.woman, OnboardingGender.man];
  return [
    for (final gender in selectable)
      AppOptionItem(
        id: onboardingGenderId(gender),
        label: onboardingGenderLabel(gender),
        icon: onboardingGenderIcon(gender),
      ),
  ];
}

String onboardingMaritalId(OnboardingMaritalStatus status) => status.name;

String onboardingMaritalLabel(OnboardingMaritalStatus status) {
  switch (status) {
    case OnboardingMaritalStatus.single:
      return 'Célibataire sans enfant';
    case OnboardingMaritalStatus.singleWithChildren:
      return 'Célibataire avec enfant(s)';
    case OnboardingMaritalStatus.divorced:
      return 'Divorcé(e)';
    case OnboardingMaritalStatus.widowed:
      return 'Veuf / veuve';
  }
}

OnboardingMaritalStatus? onboardingMaritalFromId(String id) {
  for (final value in OnboardingMaritalStatus.values) {
    if (onboardingMaritalId(value) == id) return value;
  }
  return null;
}

List<AppOptionItem> onboardingMaritalItems() {
  return [
    for (final status in OnboardingMaritalStatus.values)
      AppOptionItem(
        id: onboardingMaritalId(status),
        label: onboardingMaritalLabel(status),
      ),
  ];
}

/// Closed list for filters (Découvrir) and onboarding - never free text.
const onboardingFaithConfessions = churchDenominations;

