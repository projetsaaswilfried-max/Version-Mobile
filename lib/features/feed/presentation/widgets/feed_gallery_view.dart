import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';

class FeedGalleryView extends StatefulWidget {
  const FeedGalleryView({super.key, required this.urls});

  final List<String> urls;

  @override
  State<FeedGalleryView> createState() => _FeedGalleryViewState();
}

class _FeedGalleryViewState extends State<FeedGalleryView> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final urls = widget.urls;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: AppRadius.mdRadius,
                child: AppNetworkImage(url: urls[index]),
              );
            },
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_index + 1} / ${urls.length}',
            key: const ValueKey('feed-gallery-index'),
            style: context.typography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
