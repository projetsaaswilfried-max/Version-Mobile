import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';

class MessageImageViewerPage extends StatelessWidget {
  const MessageImageViewerPage({super.key, required this.imageUrl, this.title});

  final String imageUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              title: title == null ? null : Text(title!),
            ),
            body: Center(
              child: AppNetworkImage(
                url: imageUrl,
                fit: BoxFit.contain,
                semanticLabel: title ?? 'Image',
              ),
            ),
          );
        },
      ),
    );
  }
}
