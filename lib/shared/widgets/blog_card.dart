import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../features/blog/domain/entities/blog_post.dart';
import '../../features/property/data/repositories/property_repository.dart';
import 'property_thumbnail.dart';

class BlogCard extends ConsumerWidget {
  const BlogCard({super.key, required this.post, this.compact = false});

  final BlogPost post;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = ref.read(mediaUrlResolverProvider).resolvePropertyImageUrl(post.coverImageUrl);
    final date = DateTime.tryParse(post.publishedAt ?? post.createdAt);
    final dateLabel = date != null ? DateFormat('MMM d, yyyy').format(date) : '';

    if (compact) {
      return SizedBox(
        width: 240,
        height: 200,
        child: _BlogCardBody(
          post: post,
          imageUrl: imageUrl,
          dateLabel: dateLabel,
          imageHeight: 96,
          compact: true,
        ),
      );
    }

    return _BlogCardBody(
      post: post,
      imageUrl: imageUrl,
      dateLabel: dateLabel,
      imageHeight: 180,
      compact: false,
    );
  }
}

class _BlogCardBody extends StatelessWidget {
  const _BlogCardBody({
    required this.post,
    required this.imageUrl,
    required this.dateLabel,
    required this.imageHeight,
    required this.compact,
  });

  final BlogPost post;
  final String imageUrl;
  final String dateLabel;
  final double imageHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textBlock = Padding(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.category != null && !compact)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                post.category!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          Text(
            post.title,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            compact ? dateLabel : '${post.authorName ?? 'Editor'} · $dateLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 11 : null,
                  height: 1.15,
                ),
          ),
          if (!compact && post.excerpt != null && post.excerpt!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.excerpt!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppNavigation.openBlog(context, post.slug),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyThumbnail(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Expanded(child: textBlock),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PropertyThumbnail(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  textBlock,
                ],
              ),
      ),
    );
  }
}
