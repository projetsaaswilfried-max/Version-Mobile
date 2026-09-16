import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';
import '../../di/onboarding_providers.dart';

class _IntroSlideData {
  const _IntroSlideData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const _slides = <_IntroSlideData>[
  _IntroSlideData(
    title: 'Rencontres sincères',
    subtitle: 'Des profils qui cherchent le mariage, dans la foi.',
  ),
  _IntroSlideData(
    title: 'La foi au centre',
    subtitle: 'Confession, valeurs et projet de vie alignés.',
  ),
  _IntroSlideData(
    title: 'Prêt à commencer',
    subtitle: 'Crée ton compte ou connecte-toi en toute simplicité.',
  ),
];

/// Pre-auth Nestle-style intro carousel (3 slides) → Welcome.
class IntroOnboardingPage extends ConsumerStatefulWidget {
  const IntroOnboardingPage({super.key});

  @override
  ConsumerState<IntroOnboardingPage> createState() =>
      _IntroOnboardingPageState();
}

class _IntroOnboardingPageState extends ConsumerState<IntroOnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(introStoreProvider).markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Passer',
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 55,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.primaryLight,
                                  colors.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 88,
                                color: colors.surface.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: typography.headline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? colors.primary
                              : colors.textSecondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: isLast ? 'Continuer' : 'Suivant',
                    onPressed: isLast ? _finish : _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
