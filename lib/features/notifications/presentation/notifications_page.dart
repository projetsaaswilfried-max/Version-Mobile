import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_relative_time.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/entities/app_notification.dart';
import '../domain/notification_category.dart';
import '../domain/notification_day_section.dart';
import 'notifications_controller.dart';
import 'open_notification_target.dart';

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
                        openNotificationTarget(
                          ref,
                          type: item.type,
                          targetUrl: item.targetUrl,
                          actorId: item.actorId,
                        );
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
