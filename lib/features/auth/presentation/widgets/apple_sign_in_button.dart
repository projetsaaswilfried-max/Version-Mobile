import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Full-width labeled Apple button - noir/blanc imposé par les Human
/// Interface Guidelines d'Apple, même forme (pilule) que [AppButton].
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Material(
      color: Colors.black,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.apple, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Continuer avec Apple',
                style: typography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
