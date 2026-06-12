import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/media_url_resolver.dart';
import 'skeleton_loader.dart';

/// Video slide: poster + play button first; WebView iframe loads on tap with valid Referer.
class PropertyVideoEmbed extends StatefulWidget {
  const PropertyVideoEmbed({
    super.key,
    required this.sourceUrl,
    required this.embedUrl,
    this.posterUrl,
  });

  final String sourceUrl;
  final String embedUrl;
  final String? posterUrl;

  @override
  State<PropertyVideoEmbed> createState() => _PropertyVideoEmbedState();
}

class _PropertyVideoEmbedState extends State<PropertyVideoEmbed> {
  WebViewController? _controller;
  bool _playing = false;
  bool _loading = false;

  String get _poster {
    final explicit = widget.posterUrl;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return const MediaUrlResolver('').resolveVideoPoster(widget.sourceUrl) ?? '';
  }

  bool get _isYouTube => MediaUrlResolver.extractYouTubeVideoId(widget.sourceUrl) != null;

  @override
  void didUpdateWidget(PropertyVideoEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl || oldWidget.sourceUrl != widget.sourceUrl) {
      setState(() {
        _playing = false;
        _loading = false;
        _controller = null;
      });
    }
  }

  void _startPlayback() {
    setState(() {
      _playing = true;
      _loading = true;
    });
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(
        MediaUrlResolver.buildVideoEmbedHtml(widget.embedUrl),
        baseUrl: MediaUrlResolver.embedBaseUrl,
      );
    setState(() {});
  }

  Future<void> _openExternally() async {
    final watch = MediaUrlResolver.youTubeWatchUrl(widget.sourceUrl);
    final target = watch ?? widget.sourceUrl;
    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playing && _controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller!),
          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: _IconChip(
              icon: Icons.close,
              label: 'Poster',
              onTap: () => setState(() {
                _playing = false;
                _loading = false;
                _controller = null;
              }),
            ),
          ),
          if (_isYouTube)
            Positioned(
              bottom: 8,
              left: 8,
              child: _IconChip(
                icon: Icons.open_in_new,
                label: 'YouTube',
                onTap: _openExternally,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: _startPlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_poster.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _poster,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => const ColoredBox(
                color: Colors.black87,
                child: Center(child: SkeletonLoader(height: 48, width: 48, borderRadius: 24)),
              ),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Colors.black87,
                child: Icon(Icons.videocam, color: Colors.white54, size: 48),
              ),
            )
          else
            const ColoredBox(
              color: Colors.black87,
              child: Icon(Icons.videocam, color: Colors.white54, size: 48),
            ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          Center(child: _YouTubePlayButton(isYouTube: _isYouTube)),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Text(
              _isYouTube ? 'Tap to play on YouTube' : 'Tap to play video',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubePlayButton extends StatelessWidget {
  const _YouTubePlayButton({required this.isYouTube});

  final bool isYouTube;

  @override
  Widget build(BuildContext context) {
    if (isYouTube) {
      return Container(
        width: 68,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
