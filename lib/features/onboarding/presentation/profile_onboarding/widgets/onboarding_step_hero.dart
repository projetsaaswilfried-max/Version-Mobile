import 'package:agapeo/core/theme/app_spacing.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingStepHero extends StatelessWidget {
  const OnboardingStepHero({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;

  static const double _heroHeight = 160;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _heroHeight,
          width: double.infinity,
          child: SvgPicture.asset(
            asset,
            width: double.infinity,
            height: _heroHeight,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: typography.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
