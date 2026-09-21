import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/sign_out/confirm_and_sign_out.dart';
import '../../../profile/presentation/hub/profile_hub_body.dart';
import '../widgets/home_floating_nav_bar.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Text('Profil'),
        ),
      ),
      body: ProfileHubBody(
        bottomPadding: HomeFloatingNavBar.scrollClearance(context),
        onSignOut: () => confirmAndSignOut(context, ref),
      ),
    );
  }
}
