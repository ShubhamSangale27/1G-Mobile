import 'package:flutter/material.dart';

import '../../core/theme/responsive.dart';

enum AppLogoSize { compact, medium, large }

/// Responsive 1Guntha brand logo — same asset as the Angular web app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppLogoSize.medium});

  final AppLogoSize size;

  static const assetPath = 'assets/images/1G_logo.png';

  double _height(BuildContext context) {
    final w = Responsive.widthOf(context);
    return switch (size) {
      AppLogoSize.compact => w < 360 ? 30 : (Responsive.isTablet(context) ? 40 : 34),
      AppLogoSize.medium => w < 360 ? 72 : (Responsive.isTablet(context) ? 104 : 88),
      AppLogoSize.large => w < 360 ? 96 : (Responsive.isTablet(context) ? 148 : 120),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '1Guntha.com',
      image: true,
      child: Image.asset(
        assetPath,
        height: _height(context),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
