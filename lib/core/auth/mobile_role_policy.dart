import '../error/app_exception.dart';

/// Mobile app allows USER and AGENT only. ADMIN and BLOG must use the web app.
abstract final class MobileRolePolicy {
  static const blockedRoles = {'ADMIN', 'BLOG'};

  static const blockedLoginMessage =
      'This mobile app is for property users and field agents only. '
      'Admin and Blogger accounts must sign in on the web app at 1guntha.com.';

  static bool isAllowed(String? role) {
    if (role == null || role.isEmpty) return false;
    return !blockedRoles.contains(role.toUpperCase());
  }

  static bool isAgent(String? role) => role?.toUpperCase() == 'AGENT';

  static void ensureAllowed(String role) {
    if (!isAllowed(role)) {
      throw const ForbiddenException(blockedLoginMessage);
    }
  }
}
