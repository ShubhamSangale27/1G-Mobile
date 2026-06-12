/// Port of Angular `image-url.util.ts` — resolves property and carousel media URLs.
class MediaUrlResolver {
  const MediaUrlResolver(this.apiBaseUrl);

  /// Referer / base URL for in-app WebView embeds (YouTube policy).
  static const embedOrigin = 'https://www.1guntha.com';
  static const embedBaseUrl = 'https://www.1guntha.com/';

  final String apiBaseUrl;

  String resolvePropertyImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    final trimmed = upgradeInsecure(url.trim());
    if (trimmed.startsWith('/')) {
      final origin = apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
      return '$origin$trimmed';
    }
    final driveId = extractGoogleDriveFileId(trimmed);
    if (driveId != null) {
      return 'https://drive.google.com/thumbnail?id=$driveId&sz=w1200';
    }
    final ytId = extractYouTubeVideoId(trimmed);
    if (ytId != null) return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    return trimmed;
  }

  String? resolveVideoEmbedUrl(String? url) {
    if (url == null) return null;
    final trimmed = upgradeInsecure(url.trim());
    final ytId = extractYouTubeVideoId(trimmed);
    if (ytId != null) {
      return buildYouTubeEmbedUrl(ytId);
    }
    final driveId = extractGoogleDriveFileId(trimmed);
    if (driveId != null) return 'https://drive.google.com/file/d/$driveId/preview';
    return null;
  }

  String? resolveVideoPoster(String? url) {
    if (url == null) return null;
    final ytId = extractYouTubeVideoId(url);
    if (ytId != null) return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    final driveId = extractGoogleDriveFileId(url);
    if (driveId != null) {
      return 'https://drive.google.com/thumbnail?id=$driveId&sz=w800';
    }
    return null;
  }

  bool isAllowedVideoUrl(String url) {
    return extractYouTubeVideoId(url) != null || extractGoogleDriveFileId(url) != null;
  }

  bool isAllowedImageUrl(String url) {
    if (extractGoogleDriveFileId(url) != null) return true;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  static String upgradeInsecure(String url) {
    if (!url.startsWith('http://')) return url;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('youtube') ||
        host.contains('youtu.be') ||
        host.contains('google') ||
        host.contains('drive.google.com')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  static String? extractGoogleDriveFileId(String url) {
    if (!url.contains('drive.google.com') || url.contains('/folders/')) return null;
    final fileMatch = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (fileMatch != null) return fileMatch.group(1);
    final openMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
    return openMatch?.group(1);
  }

  static String? extractYouTubeVideoId(String url) {
    if (!url.contains('youtu')) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.replaceFirst('www.', '').toLowerCase();
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return id != null && id.length >= 6 ? id : null;
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.length >= 6) return v;
      for (final seg in ['embed', 'shorts', 'live']) {
        final idx = uri.pathSegments.indexOf(seg);
        if (idx >= 0 && idx + 1 < uri.pathSegments.length) {
          return uri.pathSegments[idx + 1];
        }
      }
    }
    return null;
  }

  /// YouTube iframe embed URL with origin (required for WebView playback).
  static String buildYouTubeEmbedUrl(String videoId, {bool autoplay = false}) {
    final params = <String, String>{
      'rel': '0',
      'modestbranding': '1',
      'playsinline': '1',
      'origin': embedOrigin,
      if (autoplay) 'autoplay': '1',
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://www.youtube.com/embed/$videoId?$query';
  }

  static String? youTubeWatchUrl(String? url) {
    final id = extractYouTubeVideoId(url ?? '');
    if (id == null) return null;
    return 'https://www.youtube.com/watch?v=$id';
  }

  /// HTML wrapper for WebView — sets referrer policy and valid base origin.
  static String buildVideoEmbedHtml(String embedUrl) {
    final src = _escapeHtmlAttribute(embedUrl);
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    iframe {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      border: 0;
    }
  </style>
</head>
<body>
  <iframe
    src="$src"
    referrerpolicy="strict-origin-when-cross-origin"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
  ></iframe>
</body>
</html>''';
  }

  static String _escapeHtmlAttribute(String value) =>
      value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');
}
