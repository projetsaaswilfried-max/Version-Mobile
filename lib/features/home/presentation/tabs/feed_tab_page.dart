import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_svg.dart';
import '../../../feed/presentation/feed_body.dart';
import '../../../notifications/presentation/notifications_controller.dart';
import '../../../notifications/presentation/notifications_page.dart';
import '../widgets/home_floating_nav_bar.dart';

class FeedTabPage extends ConsumerWidget {
  const FeedTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationsControllerProvider.select((state) => state.unreadCount),
    );
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leadingWidth: AppSpacing.xxxl + AppSpacing.lg,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: Semantics(
            label: 'Agapeo',
            image: true,
            child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
          ),
        ),
        title: const Text('Agapeo'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: unread > 0
                ? Badge(
                    label: Text('$unread'),
                    child: AppSvg(
                      AppAssets.icBell,
                      size: AppSpacing.xl,
                      color: colors.textPrimary,
                    ),
                  )
                : AppSvg(
                    AppAssets.icBell,
                    size: AppSpacing.xl,
                    color: colors.textPrimary,
                  ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: FeedBody(
        bottomPadding: HomeFloatingNavBar.scrollClearance(context),
      ),
    );
  }
}
