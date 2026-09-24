import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Full-width labeled Google button - même forme (pilule) que [AppButton].
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: colors.border)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvg(AppAssets.icGoogle, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Continuer avec Google',
                style: typography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
