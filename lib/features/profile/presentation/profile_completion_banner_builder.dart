import 'package:flutter/material.dart';

import '../domain/entities/profile_completeness.dart';
import 'hub/widgets/profile_completion_banner.dart';
import 'missing_profile_field_destination.dart';
import 'security/add_profile_photo_page.dart';

/// Bandeau de complétion réutilisé sur le Hub profil et sur Découvrir :
/// - profil incomplet (y compris sans photo) → écran du premier champ
///   manquant.
/// - profil complet mais photo non soumise ou refusée → toujours l'étape
///   photo d'abord (`AddProfilePhotoPage`), qui enchaîne elle-même sur
///   `VerificationPage` pour le selfie - les deux étapes restent collées
///   dans cet ordre à chaque (re)soumission, jamais un accès direct au
///   selfie qui saute la photo (même logique que le web qui revient
///   toujours à l'étape photo de l'onboarding).
/// - en attente de validation → message informatif, pas d'action.
/// - déjà VERIFIED → pas de bandeau.
Widget? buildProfileCompletionBanner({
  required BuildContext context,
  required ProfileCompleteness? completeness,
  required String? photoVerificationStatus,
  required VoidCallback onDismiss,
}) {
  if (completeness == null) return null;

  if (!completeness.isComplete) {
    return ProfileCompletionBanner(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              missingProfileFieldDestination(completeness.missingKeys),
        ),
      ),
      onDismiss: onDismiss,
    );
  }

  switch (photoVerificationStatus?.toUpperCase()) {
    case 'VERIFIED':
      return null;
    case 'PENDING':
      return ProfileCompletionBanner(
        icon: Icons.hourglass_top_outlined,
        title: 'Vérification en cours',
        subtitle:
            'Ton profil sera visible dans Découvrir dès validation par '
            'notre équipe.',
        onTap: () {},
        onDismiss: onDismiss,
      );
    case 'REJECTED':
      return ProfileCompletionBanner(
        icon: Icons.error_outline,
        title: 'Photo refusée',
        subtitle:
            'Reprends ta photo de profil pour soumettre une nouvelle '
            'demande - le motif du refus s\'affiche à l\'étape suivante.',
        onTap: () => _openPhotoStep(context),
        onDismiss: onDismiss,
      );
    default:
      return ProfileCompletionBanner(
        title: 'Soumets ton profil pour validation',
        subtitle:
            'Ajoute ta photo et un selfie de vérification pour apparaître '
            'dans Découvrir et être contacté par les autres membres.',
        onTap: () => _openPhotoStep(context),
        onDismiss: onDismiss,
      );
  }
}

void _openPhotoStep(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AddProfilePhotoPage()),
  );
}
