import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_shell_controller.dart';
import 'home_tab.dart';
import 'tabs/discover_tab_page.dart';
import 'tabs/feed_tab_page.dart';
import 'tabs/messages_tab_page.dart';
import 'tabs/profile_tab_page.dart';
import 'widgets/home_floating_nav_bar.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeShellIndexProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: index,
              children: [
                for (final tab in HomeTab.values)
                  _LazyTab(
                    active: index == tab.index,
                    child: switch (tab) {
                      HomeTab.feed => const FeedTabPage(),
                      HomeTab.discover => const DiscoverTabPage(),
                      HomeTab.messages => const MessagesTabPage(),
                      HomeTab.profile => const ProfileTabPage(),
                    },
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HomeFloatingNavBar(
                selectedIndex: index,
                onSelect: (i) =>
                    ref.read(homeShellIndexProvider.notifier).select(i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LazyTab extends StatefulWidget {
  const _LazyTab({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  var _visited = false;

  @override
  void initState() {
    super.initState();
    _visited = widget.active;
  }

  @override
  void didUpdateWidget(covariant _LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_visited) {
      _visited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visited) return const SizedBox.shrink();
    return widget.child;
  }
}
