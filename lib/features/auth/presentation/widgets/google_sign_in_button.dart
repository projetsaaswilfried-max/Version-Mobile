import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Nestle / Datify-style square Google button (OAuth wired in MR2).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Continuer avec Google',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.lgRadius,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(child: AppSvg(AppAssets.icGoogle, size: 28)),
          ),
        ),
      ),
    );
  }
}

void showGoogleComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Connexion Google bientôt disponible.')),
  );
}
