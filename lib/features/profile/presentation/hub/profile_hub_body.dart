import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/presentation/pages/my_posts_page.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/profile_hub_section.dart';
import '../faith/faith_page.dart';
import '../favorites/favorites_page.dart';
import '../interested/interested_page.dart';
import '../more_info/more_info_page.dart';
import '../my_profile/my_profile_page.dart';
import '../privacy/privacy_page.dart';
import '../profile_completion_banner_builder.dart';
import '../public_profile/public_profile_page.dart';
import '../security/account_security_page.dart';
import 'profile_hub_controller.dart';
import 'profile_hub_state.dart';
import 'widgets/profile_hub_error.dart';
import 'widgets/profile_hub_header.dart';
import 'widgets/profile_hub_row.dart';
import 'widgets/profile_hub_skeleton.dart';

class ProfileHubBody extends ConsumerStatefulWidget {
  const ProfileHubBody({
    super.key,
    this.bottomPadding = 0,
    this.onSignOut,
  });

  final double bottomPadding;
  final VoidCallback? onSignOut;

  @override
  ConsumerState<ProfileHubBody> createState() => _ProfileHubBodyState();
}

class _ProfileHubBodyState extends ConsumerState<ProfileHubBody> {
  var _completionDismissed = false;

  static const _accountSections = [
    ProfileHubSection.profile,
    ProfileHubSection.faith,
    ProfileHubSection.moreInfo,
  ];

  static const _activitySections = [
    ProfileHubSection.posts,
    ProfileHubSection.favorites,
    ProfileHubSection.interested,
  ];

  static const _settingsSections = [
    ProfileHubSection.privacy,
    ProfileHubSection.account,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileHubControllerProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(profileHubControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._slivers(context, ref, state),
          SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
        ],
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    ProfileHubState state,
  ) {
    if (state.isInitialLoading) {
      return const [SliverToBoxAdapter(child: ProfileHubSkeleton())];
    }
    if (state.errorMessage != null && state.hub == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              Expanded(
                child: ProfileHubError(
                  onRetry: () =>
                      ref.read(profileHubControllerProvider.notifier).retry(),
                ),
              ),
              if (widget.onSignOut != null) _logoutGroup(context),
            ],
          ),
        ),
      ];
    }

    final hub = state.hub;
    if (hub == null) {
      return const [SliverToBoxAdapter(child: ProfileHubSkeleton())];
    }

    final completeness = ref.watch(profileCompletenessProvider).asData?.value;
    final photoVerificationStatus = switch (ref
        .watch(profileFieldsProvider)
        .asData
        ?.value) {
      Ok(:final value) => value.photoVerificationStatus,
      _ => null,
    };
    final completionBanner = _completionDismissed
        ? null
        : buildProfileCompletionBanner(
            context: context,
            completeness: completeness,
            photoVerificationStatus: photoVerificationStatus,
            onDismiss: () => setState(() => _completionDismissed = true),
          );

    return [
      SliverToBoxAdapter(
        child: ProfileHubHeader(
          hub: hub,
          onViewPublicProfile: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PublicProfilePage(),
              ),
            );
          },
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MyProfilePage(),
              ),
            );
          },
        ),
      ),
      if (completionBanner != null) SliverToBoxAdapter(child: completionBanner),
      SliverToBoxAdapter(
        child: AppSettingsGroup(
          title: 'Mon compte',
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          children: [
            for (final section in _accountSections)
              ProfileHubRow(
                section: section,
                onTap: () => _onSectionTap(context, section),
              ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: AppSettingsGroup(
          title: 'Activité',
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          children: [
            for (final section in _activitySections)
              ProfileHubRow(
                section: section,
                onTap: () => _onSectionTap(context, section),
              ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: AppSettingsGroup(
          title: 'Réglages',
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          children: [
            for (final section in _settingsSections)
              ProfileHubRow(
                section: section,
                onTap: () => _onSectionTap(context, section),
              ),
          ],
        ),
      ),
      if (widget.onSignOut != null)
        SliverToBoxAdapter(child: _logoutGroup(context)),
    ];
  }

  Widget _logoutGroup(BuildContext context) {
    return AppSettingsGroup(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        AppSettingsRow(
          label: 'Déconnexion',
          icon: Icons.logout,
          danger: true,
          compact: true,
          showChevron: false,
          onTap: widget.onSignOut!,
        ),
      ],
    );
  }

  void _onSectionTap(BuildContext context, ProfileHubSection section) {
    final page = switch (section) {
      ProfileHubSection.profile => const MyProfilePage(),
      ProfileHubSection.faith => const FaithPage(),
      ProfileHubSection.moreInfo => const MoreInfoPage(),
      ProfileHubSection.posts => const MyPostsPage(),
      ProfileHubSection.favorites => const FavoritesPage(),
      ProfileHubSection.interested => const InterestedPage(),
      ProfileHubSection.privacy => const PrivacyPage(),
      ProfileHubSection.account => const AccountSecurityPage(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
