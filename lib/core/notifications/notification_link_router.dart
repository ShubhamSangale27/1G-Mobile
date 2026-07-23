/// Resolves push notification tap targets to in-app routes or external URLs.
class NotificationLinkRouter {
  static const appHosts = {'1guntha.com', 'www.1guntha.com', 'localhost', '127.0.0.1'};

  /// Returns an in-app route (starting with `/`) or null if the link should open externally.
  static String? resolveInAppRoute({
    required String? linkUrl,
    required String linkTarget,
  }) {
    if (linkUrl == null || linkUrl.trim().isEmpty) return null;
    if (linkTarget.toUpperCase() == 'EXTERNAL') return null;

    final trimmed = linkUrl.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri == null || !uri.hasScheme) {
      return trimmed.startsWith('/') ? trimmed : '/$trimmed';
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (_isAppHost(uri.host)) {
        final path = uri.path.isEmpty ? '/' : uri.path;
        return uri.hasQuery ? '$path?${uri.query}' : path;
      }
      return null;
    }

    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static bool shouldOpenExternally({
    required String? linkUrl,
    required String linkTarget,
  }) {
    if (linkUrl == null || linkUrl.trim().isEmpty) return false;
    if (linkTarget.toUpperCase() == 'EXTERNAL') return true;

    final uri = Uri.tryParse(linkUrl.trim());
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return !_isAppHost(uri.host);
  }

  static bool _isAppHost(String host) {
    final normalized = host.toLowerCase();
    return appHosts.contains(normalized);
  }
}
