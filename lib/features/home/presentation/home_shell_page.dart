import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import 'home_shell_controller.dart';
import 'home_tab.dart';
import 'tabs/discover_tab_page.dart';
import 'tabs/feed_tab_page.dart';
import 'tabs/messages_tab_page.dart';
import 'tabs/profile_tab_page.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeShellIndexProvider);
    final colors = context.colors;

    Widget tabIcon(String asset, {required bool selected}) {
      return AppSvg(
        asset,
        size: 24,
        color: selected ? colors.primary : colors.textSecondary,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          for (final tab in HomeTab.values)
            switch (tab) {
              HomeTab.feed => const FeedTabPage(),
              HomeTab.discover => const DiscoverTabPage(),
              HomeTab.messages => const MessagesTabPage(),
              HomeTab.profile => const ProfileTabPage(),
            },
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: colors.surface,
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeShellIndexProvider.notifier).select(i),
        destinations: [
          for (final tab in HomeTab.values)
            switch (tab) {
              HomeTab.feed => NavigationDestination(
                  icon: tabIcon(AppAssets.icFeed, selected: false),
                  selectedIcon: tabIcon(AppAssets.icFeed, selected: true),
                  label: 'Fil',
                ),
              HomeTab.discover => NavigationDestination(
                  icon: tabIcon(AppAssets.icDiscover, selected: false),
                  selectedIcon: tabIcon(AppAssets.icDiscover, selected: true),
                  label: 'Découvrir',
                ),
              HomeTab.messages => NavigationDestination(
                  icon: tabIcon(AppAssets.icChat, selected: false),
                  selectedIcon: tabIcon(AppAssets.icChat, selected: true),
                  label: 'Messages',
                ),
              HomeTab.profile => NavigationDestination(
                  icon: tabIcon(AppAssets.icProfile, selected: false),
                  selectedIcon: tabIcon(AppAssets.icProfile, selected: true),
                  label: 'Profil',
                ),
            },
        ],
      ),
    );
  }
}
