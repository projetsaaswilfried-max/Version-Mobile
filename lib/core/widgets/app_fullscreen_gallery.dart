import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_network_image.dart';

/// Visionneuse plein écran, swipe entre plusieurs photos — ouverte au tap
/// sur une photo de profil (hero ou galerie).
class AppFullscreenGallery extends StatefulWidget {
  const AppFullscreenGallery({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
    this.semanticName,
  });

  final List<String> photoUrls;
  final int initialIndex;
  final String? semanticName;

  static Future<void> open(
    BuildContext context, {
    required List<String> photoUrls,
    int initialIndex = 0,
    String? semanticName,
  }) {
    if (photoUrls.isEmpty) return Future<void>.value();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppFullscreenGallery(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
          semanticName: semanticName,
        ),
      ),
    );
  }

  @override
  State<AppFullscreenGallery> createState() => _AppFullscreenGalleryState();
}

class _AppFullscreenGalleryState extends State<AppFullscreenGallery> {
  late var _index = widget.initialIndex.clamp(0, widget.photoUrls.length - 1);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          final urls = widget.photoUrls;
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              title: urls.length > 1
                  ? Text('${_index + 1} / ${urls.length}')
                  : null,
            ),
            body: PageView.builder(
              controller: PageController(initialPage: _index),
              itemCount: urls.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return AppNetworkImage(
                  url: urls[index],
                  fit: BoxFit.contain,
                  semanticLabel: widget.semanticName,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
