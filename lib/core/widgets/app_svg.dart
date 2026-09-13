import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG asset from [AppAssets], optionally tinted.
class AppSvg extends StatelessWidget {
  const AppSvg(this.assetPath, {super.key, this.size, this.color});

  final String assetPath;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
