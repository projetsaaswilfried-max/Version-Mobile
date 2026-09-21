import 'package:flutter/material.dart';

import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/profile_hub_section.dart';

class ProfileHubRow extends StatelessWidget {
  const ProfileHubRow({super.key, required this.section, required this.onTap});

  final ProfileHubSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSettingsRow(
      label: section.label,
      icon: _iconFor(section),
      compact: true,
      onTap: onTap,
    );
  }

  static IconData _iconFor(ProfileHubSection section) {
    return switch (section) {
      ProfileHubSection.profile => Icons.person_outline,
      ProfileHubSection.faith => Icons.menu_book_outlined,
      ProfileHubSection.moreInfo => Icons.tune,
      ProfileHubSection.posts => Icons.article_outlined,
      ProfileHubSection.favorites => Icons.favorite_outline,
      ProfileHubSection.interested => Icons.visibility_outlined,
      ProfileHubSection.privacy => Icons.lock_outline,
      ProfileHubSection.account => Icons.shield_outlined,
    };
  }
}
