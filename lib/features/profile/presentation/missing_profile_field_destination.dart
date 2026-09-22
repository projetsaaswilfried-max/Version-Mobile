import 'package:flutter/widgets.dart';

import '../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import '../domain/entities/profile_field_keys.dart';
import 'more_info/more_info_page.dart';
import 'my_profile/my_profile_page.dart';

/// Écran à ouvrir pour compléter un profil, selon les champs manquants
/// (`ProfileCompleteness.missingKeys`) — utilisé par le bandeau de
/// complétion sur le Hub profil et sur Découvrir.
Widget missingProfileFieldDestination(List<String> missingKeys) {
  final needOnboarding =
      missingKeys.contains(ProfileFieldKeys.gender) ||
      missingKeys.contains(ProfileFieldKeys.birthDate) ||
      missingKeys.contains(ProfileFieldKeys.country);
  if (needOnboarding) return const OnboardingFlowPage();

  final missingPhoto = missingKeys.contains(ProfileFieldKeys.photo);
  if (missingKeys.contains(ProfileFieldKeys.hobbies) && !missingPhoto) {
    return const MoreInfoPage();
  }
  return MyProfilePage(focusPhotos: missingPhoto);
}
