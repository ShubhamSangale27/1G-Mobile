import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/route_paths.dart';

/// Centralized navigation with debounce to prevent double-push freezes.
abstract final class AppNavigation {
  static String? _lastLocation;
  static DateTime? _lastNavAt;

  static bool _shouldSkip(String location) {
    final now = DateTime.now();
    if (_lastLocation == location &&
        _lastNavAt != null &&
        now.difference(_lastNavAt!) < const Duration(milliseconds: 500)) {
      return true;
    }
    _lastLocation = location;
    _lastNavAt = now;
    return false;
  }

  static void push(BuildContext context, String location) {
    if (_shouldSkip(location)) return;
    context.push(location);
  }

  static void go(BuildContext context, String location) {
    if (_shouldSkip(location)) return;
    context.go(location);
  }

  static void openProperty(BuildContext context, int propertyId) {
    push(context, RoutePaths.propertyDetail(propertyId));
  }

  static void openBlog(BuildContext context, String slug) {
    push(context, RoutePaths.blogDetail(slug));
  }

  static void openSearch(
    BuildContext context, {
    String? city,
    String? listingType,
  }) {
    final params = <String, String>{};
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (listingType != null && listingType.isNotEmpty) params['listingType'] = listingType;
    final uri = Uri(path: RoutePaths.search, queryParameters: params.isEmpty ? null : params);
    push(context, uri.toString());
  }

  static void openLogin(BuildContext context, {String? redirect}) {
    if (redirect != null && redirect.isNotEmpty) {
      push(context, '${RoutePaths.login}?redirect=${Uri.encodeComponent(redirect)}');
    } else {
      push(context, RoutePaths.login);
    }
  }
}
