import 'package:flutter/material.dart';

import '../domain/entities/profile_completeness.dart';
import 'hub/widgets/profile_completion_banner.dart';
import 'missing_profile_field_destination.dart';
import 'security/verification_page.dart';

/// Bandeau de complétion réutilisé sur le Hub profil et sur Découvrir :
/// - profil incomplet → « Complète ton profil », ouvre l'écran manquant.
/// - profil complet mais pas encore vérifié/soumis → CTA vers la
///   vérification d'identité (sinon rien ne pousse l'utilisateur à
///   soumettre une fois tous les champs remplis).
/// - déjà VERIFIED ou PENDING → pas de bandeau.
Widget? buildProfileCompletionBanner({
  required BuildContext context,
  required ProfileCompleteness? completeness,
  required String? photoVerificationStatus,
  required VoidCallback onDismiss,
}) {
  if (completeness == null) return null;

  if (!completeness.isComplete) {
    return ProfileCompletionBanner(
      percent: completeness.percentComplete,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              missingProfileFieldDestination(completeness.missingKeys),
        ),
      ),
      onDismiss: onDismiss,
    );
  }

  final status = photoVerificationStatus?.toUpperCase();
  if (status == 'VERIFIED' || status == 'PENDING') return null;

  return ProfileCompletionBanner(
    percent: 100,
    title: 'Profil complet - valide ton identité',
    subtitle: 'Passe la vérification pour apparaître dans Découvrir.',
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VerificationPage()),
    ),
    onDismiss: onDismiss,
  );
}
