import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'shimmer_box.dart';

/// Hero header for Insights & Guides with modern gradient overlay.
class BlogHeroHeader extends StatelessWidget {
  const BlogHeroHeader({super.key, this.expandedHeight = 220, this.coverImageUrl});

  final double expandedHeight;
  final String? coverImageUrl;

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    final imageUrl = (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty)
        ? coverImageUrl!
        : _fallbackImage;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14, right: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights & Guides',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            shadows: const [Shadow(color: Colors.black38, blurRadius: 10)],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expert tips for India\'s property market',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.1,
                            shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerBox(height: 220, borderRadius: 0),
              errorWidget: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0C4A6E), AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.55),
                    AppColors.primary.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 56),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
