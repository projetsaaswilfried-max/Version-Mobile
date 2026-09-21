import 'package:flutter/material.dart';

import '../domain/entities/discover_profile.dart';
import '../domain/premium/discover_premium_gate.dart';
import 'discover_state.dart';
import 'widgets/discover_profile_sheet.dart';

/// Ouvre la fiche complète d'un profil Découvrir avec les mêmes règles de
/// gating (like/favori/invitation) — partagé entre la liste principale et
/// la page de recherche dédiée pour éviter que les deux dérivent.
void openDiscoverProfileSheet(
  BuildContext context, {
  required DiscoverProfile profile,
  required DiscoverState state,
  required VoidCallback onVerifyProfile,
}) {
  DiscoverProfileSheet.show(
    context,
    profileId: profile.id,
    scoreHint: profile.score,
    canLike: canLikeDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    ),
    canFavorite: canFavoriteDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    ),
    canInvite: canInviteDiscoverProfile(
      visitorVerified: state.visitorVerified,
      isStaff: state.visitorIsStaff,
    ),
    visitorVerified: state.visitorVerified,
    subscriptionStatus: state.subscriptionStatus,
    visitorIsStaff: state.visitorIsStaff,
    onVerifyProfile: onVerifyProfile,
  );
}
