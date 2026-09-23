import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_fullscreen_gallery.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/presentation/widgets/profile_personal_posts_section.dart';
import '../../../profile/domain/mapping/marital_status_label.dart';
import '../../domain/entities/discover_profile_detail.dart';

/// Contenu scrollable de la fiche Découvrir - layout Datify (PRD §6).
class DiscoverProfileContent extends StatelessWidget {
  const DiscoverProfileContent({super.key, required this.detail});

  final DiscoverProfileDetail detail;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    final age = detail.age?.toString();
    final meta = _metaRows(detail);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoCarousel(
            photoUrls: detail.photoUrls,
            semanticName: detail.displayName,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(detail.displayName, style: typography.headline),
              ),
              if (age != null && age.isNotEmpty)
                Text(
                  ' ($age)',
                  style: typography.headline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (detail.isVerified) ...[
                const SizedBox(width: AppSpacing.xs),
                const AppVerifiedBadge(),
              ],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final row in meta) ...[
              row,
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (_textBlock(detail.bio) case final bio?)
            AppProfileSection(
              title: 'À propos',
              child: Text(bio, style: typography.bodyLarge),
            ),
          if (_textBlock(detail.whyMarriage) case final why?)
            AppProfileSection(
              title: 'Pourquoi le mariage',
              child: Text(why, style: typography.bodyLarge),
            ),
          if (_faithChips(detail) case final faith when faith.isNotEmpty)
            AppProfileSection(
              title: 'Foi',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: faith,
              ),
            ),
          if (_textBlock(detail.verse) case final verse?)
            AppProfileSection(
              title: 'Verset préféré',
              child: Text(
                verse,
                style: typography.bodyLarge.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.textSecondary,
                ),
              ),
            ),
          if (_textBlock(detail.testimony) case final testimony?)
            AppProfileSection(
              title: 'Témoignage',
              child: Text(testimony, style: typography.bodyLarge),
            ),
          if (detail.values.isNotEmpty)
            AppProfileSection(
              title: 'Valeurs',
              child: AppTagWrap(labels: detail.values, outlined: true),
            ),
          if (detail.hobbies.isNotEmpty)
            AppProfileSection(
              title: 'Loisirs',
              child: AppTagWrap(labels: detail.hobbies, outlined: true),
            ),
          if (detail.qualities.isNotEmpty)
            AppProfileSection(
              title: 'Qualités',
              child: AppTagWrap(labels: detail.qualities, outlined: true),
            ),
          if (detail.photoUrls.length > 1)
            AppProfileSection(
              title: 'Galerie',
              child: AppProfileGallery(
                photoUrls: detail.photoUrls.skip(1).toList(),
                semanticName: detail.displayName,
              ),
            ),
          ProfilePersonalPostsSection(authorId: detail.id),
        ],
      ),
    );
  }

  static String? _textBlock(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? _genderLabel(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'FEMALE':
        return 'Femme';
      case 'MALE':
        return 'Homme';
      default:
        return null;
    }
  }

  static List<_MetaRow> _metaRows(DiscoverProfileDetail detail) {
    final rows = <_MetaRow>[];
    void add(IconData icon, String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      rows.add(_MetaRow(icon: icon, label: text));
    }

    add(Icons.person_outline, _genderLabel(detail.gender));
    add(
      Icons.straighten,
      detail.heightCm == null ? null : '${detail.heightCm} cm',
    );
    add(Icons.work_outline, detail.profession);
    add(Icons.favorite_border, maritalStatusLabel(detail.maritalStatus));
    add(Icons.location_on_outlined, detail.city);
    add(Icons.public_outlined, detail.country);
    return rows;
  }

  static List<Widget> _faithChips(DiscoverProfileDetail detail) {
    final chips = <Widget>[];
    final confession = detail.confession?.trim();
    final engagement = detail.spiritualEngagement?.trim();
    if (confession != null && confession.isNotEmpty) {
      chips.add(
        AppTagChip(
          label: confession,
          icon: Icons.menu_book_outlined,
          outlined: true,
        ),
      );
    }
    if (engagement != null && engagement.isNotEmpty) {
      chips.add(AppTagChip(label: engagement, outlined: true));
    }
    return chips;
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.lg, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: context.typography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({
    required this.photoUrls,
    required this.semanticName,
  });

  final List<String> photoUrls;
  final String semanticName;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final urls = widget.photoUrls;
    final count = urls.isEmpty ? 1 : urls.length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlRadius,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (urls.isEmpty)
                AppAvatarPlaceholder(name: widget.semanticName)
              else
                PageView.builder(
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () => AppFullscreenGallery.open(
                        context,
                        photoUrls: urls,
                        initialIndex: i,
                        semanticName: widget.semanticName,
                      ),
                      child: AppNetworkImage(
                        url: urls[i],
                        semanticLabel: widget.semanticName,
                      ),
                    );
                  },
                ),
              if (count > 1)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Row(
                    children: [
                      for (var i = 0; i < count; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? colors.onScrim
                                  : colors.onScrim.withValues(alpha: 0.35),
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: const SizedBox(height: 3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
