import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/root_navigator.dart';
import '../../discover/domain/premium/discover_premium_gate.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../discover/presentation/widgets/discover_profile_sheet.dart';
import '../../home/presentation/home_shell_controller.dart';
import '../../home/presentation/home_tab.dart';
import '../../messages/presentation/thread/conversation_thread_page.dart';
import '../../premium/presentation/premium_plan_page.dart';
import '../../profile/presentation/security/add_profile_photo_page.dart';
import '../../profile/presentation/security/verification_page.dart';
import '../../support/presentation/support_list_page.dart';
import 'notifications_page.dart';

/// Route vers la destination d'une notification - sur `type` (fiable,
/// liste confirmée par le porteur) plutôt que `targetUrl` (pensé pour le
/// web, `/messages?conversation=...`), sauf pour extraire l'id de
/// conversation, faute d'un champ dédié.
///
/// Utilisé à deux endroits avec les mêmes trois champs (le backend
/// confirme que le payload push transporte exactement les mêmes données
/// que la table `notifications`, donc la même route) :
/// - tap sur une ligne de [NotificationsPage] (`AppNotification`) ;
/// - tap sur un push FCM reçu app fermée/en fond (`RemoteMessage.data`).
///
/// Pas de [BuildContext] requis : navigue via [rootNavigatorKey], comme
/// [AuthDeepLinkListener] - utilisable aussi bien depuis un widget que
/// depuis un listener global sans contexte.
void openNotificationTarget(
  WidgetRef ref, {
  required String? type,
  required String? targetUrl,
  required String? actorId,
}) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  void toRoot() => navigator.popUntil((route) => route.isFirst);
  void switchTab(HomeTab tab) {
    toRoot();
    ref.read(homeShellIndexProvider.notifier).select(tab.index);
  }

  void openConversationOr(HomeTab fallbackTab) {
    final conversationId = _conversationIdFrom(targetUrl);
    if (conversationId == null) {
      switchTab(fallbackTab);
      return;
    }
    toRoot();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationThreadPage(conversationId: conversationId),
      ),
    );
  }

  void openProfileOr(HomeTab fallbackTab) {
    if (actorId == null) {
      switchTab(fallbackTab);
      return;
    }
    final sheetContext = navigator.overlay?.context;
    if (sheetContext == null) {
      switchTab(fallbackTab);
      return;
    }
    toRoot();
    final state = ref.read(discoverControllerProvider);
    DiscoverProfileSheet.show(
      sheetContext,
      profileId: actorId,
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
      onVerifyProfile: () {
        // Photo puis selfie, toujours dans cet ordre (D34).
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const AddProfilePhotoPage()),
        );
      },
    );
  }

  switch (type) {
    case 'NEW_MESSAGE':
    case 'CONVERSATION_INVITE':
    case 'MATCH_REQUEST':
    case 'MATCH_ACCEPTED':
    case 'CONVERSATION_ACCEPTED':
      openConversationOr(HomeTab.messages);
    case 'NEW_FAVORITE':
    case 'PROFILE_LIKE':
    case 'PROFILE_VISIT':
      openProfileOr(HomeTab.discover);
    case 'NEW_RECOMMENDATION':
      switchTab(HomeTab.discover);
    case 'POST_LIKE':
    case 'POST_COMMENT':
    case 'OFFICIAL_POST':
    case 'NEW_RESOURCE':
      // Pas encore de route par id (post/ressource) - on ouvre le fil, le
      // membre peut y retrouver la publication concernée.
      switchTab(HomeTab.feed);
    case 'SUPPORT_REPLY':
      toRoot();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SupportListPage()),
      );
    case 'PHOTO_APPROVED':
    case 'PHOTO_REJECTED':
      toRoot();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const VerificationPage()),
      );
    case 'PAYMENT_FAILED':
      toRoot();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const PremiumPlanPage()),
      );
    default:
      // Type non reconnu (ou absent du payload push) - dernier recours sur
      // targetUrl si elle contient un id de conversation, sinon on ne
      // devine rien (comportement historique).
      final conversationId = _conversationIdFrom(targetUrl);
      if (conversationId == null) return;
      toRoot();
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationThreadPage(conversationId: conversationId),
        ),
      );
  }
}

String? _conversationIdFrom(String? targetUrl) {
  if (targetUrl == null) return null;
  return Uri.tryParse(targetUrl)?.queryParameters['conversation'];
}
