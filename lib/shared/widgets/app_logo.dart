import 'package:flutter/material.dart';

import '../../core/theme/responsive.dart';

enum AppLogoSize { compact, medium, large }

/// Complete brand logo as one PNG (icon, wordmark, and Devanagari tagline baked in).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.maxWidth,
    this.maxHeight,
  });

  final AppLogoSize size;
  final double? maxWidth;
  final double? maxHeight;

  static const assetPath = 'assets/images/1G_logo_full.png';
  static const tagline = 'घर प्रत्येकासाठी';

  /// Source artwork 553×431.
  static const aspectRatio = 553 / 431;

  double _preferredWidth(BuildContext context) {
    final w = Responsive.widthOf(context);
    final isTablet = Responsive.isTablet(context);
    return switch (size) {
      AppLogoSize.compact => isTablet ? 96.0 : (w < 360 ? 76.0 : 88.0),
      AppLogoSize.medium => isTablet ? w * 0.34 : w * 0.50,
      AppLogoSize.large => isTablet ? w * 0.40 : w * 0.58,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundW = _minPositive(maxWidth, constraints.maxWidth);
        final boundH = _minPositive(maxHeight, constraints.maxHeight);

        var width = _preferredWidth(context);
        var height = width / aspectRatio;

        if (boundW != null && width > boundW) {
          width = boundW;
          height = width / aspectRatio;
        }
        if (boundH != null && height > boundH) {
          height = boundH;
          width = height * aspectRatio;
        }

        return Semantics(
          label: '1Guntha.com — $tagline',
          image: true,
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}

double? _minPositive(double? a, double b) {
  double? result;
  if (a != null && a.isFinite && a > 0) result = a;
  if (b.isFinite && b > 0) {
    result = result == null ? b : (b < result ? b : result);
  }
  return result;
}
