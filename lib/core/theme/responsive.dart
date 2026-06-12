import 'package:flutter/material.dart';

/// Breakpoints and helpers for phone / tablet layouts.
class Responsive {
  Responsive._();

  static const double tablet = 600;
  static const double largeTablet = 900;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isTablet(BuildContext context) => widthOf(context) >= tablet;

  static int gridCrossAxisCount(BuildContext context, {int phone = 2, int tabletCols = 3, int large = 4}) {
    final w = widthOf(context);
    if (w >= largeTablet) return large;
    if (w >= tablet) return tabletCols;
    return phone;
  }

  static double gridChildAspectRatio(BuildContext context) {
    final w = widthOf(context);
    if (w >= largeTablet) return 0.78;
    if (w >= tablet) return 0.72;
    return 0.68;
  }

  static double horizontalCardWidth(BuildContext context) {
    final w = widthOf(context);
    if (w >= largeTablet) return 300;
    if (w >= tablet) return 280;
    return w * 0.72;
  }

  static double featuredStripHeight(BuildContext context) => isTablet(context) ? 328 : 304;

  static double blogCompactStripHeight(BuildContext context) => isTablet(context) ? 216 : 200;

  static EdgeInsets screenPadding(BuildContext context) {
    final w = widthOf(context);
    final h = MediaQuery.sizeOf(context).height;
    return EdgeInsets.symmetric(horizontal: w >= tablet ? 24 : 16, vertical: h >= tablet ? 12 : 8);
  }
}
