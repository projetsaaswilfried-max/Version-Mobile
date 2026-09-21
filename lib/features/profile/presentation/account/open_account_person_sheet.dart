import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../discover/domain/premium/discover_premium_gate.dart';
import '../../../discover/presentation/widgets/discover_premium_sheet.dart';
import '../../../discover/presentation/widgets/discover_profile_sheet.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/profile_fields_snapshot.dart';

Future<void> openAccountPersonSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String profileId,
  required bool identityRevealed,
}) async {
  if (!identityRevealed) {
    await DiscoverPremiumSheet.show(context);
    return;
  }
  final fields = switch (ref.read(profileFieldsProvider).asData?.value) {
    Ok<ProfileFieldsSnapshot>(:final value) => value,
    _ => null,
  };
  final verified =
      (fields?.photoVerificationStatus ?? '').toUpperCase() == 'VERIFIED';
  final gate = await ref.read(profileGateRepositoryProvider).fetchGate();
  final subscription = switch (gate) {
    Ok(:final value) => value.subscriptionStatus.name.toUpperCase(),
    Err() => 'FREE',
  };
  if (!context.mounted) return;
  await DiscoverProfileSheet.show(
    context,
    profileId: profileId,
    visitorVerified: verified,
    subscriptionStatus: subscription,
    canLike: canLikeDiscoverProfile(visitorVerified: verified, isStaff: false),
    canFavorite: canFavoriteDiscoverProfile(
      visitorVerified: verified,
      isStaff: false,
    ),
    canInvite: canInviteDiscoverProfile(
      visitorVerified: verified,
      isStaff: false,
    ),
  );
}
