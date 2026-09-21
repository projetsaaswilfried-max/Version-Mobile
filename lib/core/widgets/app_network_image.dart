import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_skeleton_box.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String url;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => const AppSkeletonBox(),
      errorWidget: (context, url, error) => ColoredBox(
        color: colors.muted,
        child: Icon(Icons.broken_image_outlined, color: colors.textSecondary),
      ),
    );
    final label = semanticLabel;
    if (label == null) return image;
    return Semantics(image: true, label: label, child: image);
  }
}
