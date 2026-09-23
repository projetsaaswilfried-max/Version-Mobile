import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_relative_time.dart';
import '../../../core/widgets/widgets.dart';
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
import '../domain/entities/app_notification.dart';
import '../domain/notification_category.dart';
import '../domain/notification_day_section.dart';
import 'notifications_controller.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllRead,
              child: Text(
                'Tout lire',
                style: context.typography.label.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(selected: state.filter, onSelected: notifier.setFilter),
          Expanded(
            child: state.isLoading
                ? const _NotificationsSkeleton()
                : state.errorMessage != null
                ? AppEmptyState(
                    icon: Icons.error_outline,
                    title: 'Impossible de charger',
                    detail: state.errorMessage,
                    actionLabel: 'Réessayer',
                    actionVariant: AppButtonVariant.primary,
                    onAction: notifier.load,
                  )
                : state.visible.isEmpty
                ? AppEmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'Aucune notification',
                    detail: _emptyDetail(state.filter),
                  )
                : RefreshIndicator(
                    color: colors.primary,
                    onRefresh: () => notifier.load(silent: true),
                    child: _NotificationsList(
                      items: state.visible,
                      onTap: (item) {
                        notifier.markRead(item.id);
                        _openNotificationTarget(context, ref, item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _emptyDetail(AppNotificationCategory filter) {
    return switch (filter) {
      AppNotificationCategory.unread =>
        'Tu es à jour - aucune notification non lue.',
      AppNotificationCategory.all =>
        'Les likes, messages et nouveautés apparaîtront ici.',
      _ => 'Aucune notification dans cette catégorie.',
    };
  }
}

/// Route le tap sur une notification vers sa destination - sur `type`
/// (fiable, liste confirmée par le porteur) plutôt que `target_url`
/// (pensé pour le web, `/messages?conversation=...`, `/discover`).
/// L'id de conversation reste extrait de `target_url` faute d'un champ
/// dédié sur `AppNotification`.
void _openNotificationTarget(
  BuildContext context,
  WidgetRef ref,
  AppNotification item,
) {
  final navigator = Navigator.of(context, rootNavigator: true);
  void toRoot() => navigator.popUntil((route) => route.isFirst);
  void switchTab(HomeTab tab) {
    toRoot();
    ref.read(homeShellIndexProvider.notifier).select(tab.index);
  }

  void openConversationOr(HomeTab fallbackTab) {
    final conversationId = _conversationIdFrom(item.targetUrl);
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
    final actorId = item.actorId;
    if (actorId == null) {
      switchTab(fallbackTab);
      return;
    }
    toRoot();
    final state = ref.read(discoverControllerProvider);
    DiscoverProfileSheet.show(
      context,
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

  switch (item.type) {
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
      // Type non reconnu (ou ancien format) - dernier recours sur
      // target_url si elle contient un id de conversation, sinon on ne
      // devine rien (comportement historique).
      final conversationId = _conversationIdFrom(item.targetUrl);
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final AppNotificationCategory selected;
  final ValueChanged<AppNotificationCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SizedBox(
        height: AppSpacing.xxxl + AppSpacing.sm,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < AppNotificationCategory.values.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: AppNotificationCategory.values[i].label,
                  selected: selected == AppNotificationCategory.values[i],
                  onTap: () => onSelected(AppNotificationCategory.values[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.chipBackground,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: typography.label.copyWith(
                color: selected ? colors.surface : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.items, required this.onTap});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final sections = groupNotificationsByDay(items);
    final children = <Widget>[];
    for (final (section, sectionItems) in sections) {
      children.add(_SectionHeader(label: section.label));
      for (var i = 0; i < sectionItems.length; i++) {
        children.add(
          _NotificationTile(item: sectionItems[i], onTap: () => onTap(sectionItems[i])),
        );
        if (i < sectionItems.length - 1) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxxl * 2),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.colors.border.withValues(alpha: 0.65),
              ),
            ),
          );
        }
      }
    }
    children.add(const SizedBox(height: AppSpacing.xxxl));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: context.typography.label.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final (icon, iconColor) = _categoryVisual(item.category, colors);
    final title = item.aggregateCount > 1
        ? '${item.title} (${item.aggregateCount})'
        : item.title;

    return Material(
      color: item.isRead
          ? colors.surface
          : colors.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.xxxl + AppSpacing.sm,
                height: AppSpacing.xxxl + AppSpacing.sm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(alpha: 0.22),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(icon, color: iconColor, size: AppSpacing.xl),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: typography.bodyLarge.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatRelativeTime(item.createdAt),
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (!item.isRead) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Container(
                            width: AppSpacing.sm,
                            height: AppSpacing.sm,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Non lue',
                            style: typography.bodySmall.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _categoryVisual(
    AppNotificationCategory category,
    AppColors colors,
  ) {
    return switch (category) {
      AppNotificationCategory.messages => (
        Icons.chat_bubble_rounded,
        colors.primary,
      ),
      AppNotificationCategory.profile => (
        Icons.favorite_rounded,
        colors.primaryLight,
      ),
      AppNotificationCategory.posts => (
        Icons.article_rounded,
        colors.verified,
      ),
      AppNotificationCategory.recommendations => (
        Icons.auto_awesome_rounded,
        colors.warning,
      ),
      AppNotificationCategory.platform => (
        Icons.campaign_rounded,
        colors.textSecondary,
      ),
      _ => (Icons.notifications_rounded, colors.textSecondary),
    };
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(
            width: AppSpacing.xxxl + AppSpacing.sm,
            height: AppSpacing.xxxl + AppSpacing.sm,
            shape: BoxShape.circle,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(
                  height: AppSpacing.md,
                  width: AppSpacing.skeletonTitleWidth + AppSpacing.xl,
                  borderRadius: AppRadius.smRadius,
                ),
                SizedBox(height: AppSpacing.sm),
                AppSkeletonBox(
                  height: AppSpacing.sm + 2,
                  width: double.infinity,
                  borderRadius: AppRadius.smRadius,
                ),
                SizedBox(height: AppSpacing.sm),
                AppSkeletonBox(
                  height: AppSpacing.sm,
                  width: AppSpacing.skeletonMetaWidth,
                  borderRadius: AppRadius.smRadius,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
