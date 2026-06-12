import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/repositories/blog_repository.dart';
import '../../domain/entities/blog_post.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  BlogPost? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(blogRepositoryProvider).getBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMapper.toUserMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(mediaUrlResolverProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: SkeletonLoader(height: 300, borderRadius: 16))
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _post == null
                  ? const EmptyView(message: 'Article not found.')
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: _post!.coverImageUrl != null ? 240 : 0,
                          pinned: true,
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                          ),
                          flexibleSpace: _post!.coverImageUrl != null
                              ? FlexibleSpaceBar(
                                  background: CachedNetworkImage(
                                    imageUrl: resolver.resolvePropertyImageUrl(_post!.coverImageUrl),
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: AppColors.border),
                                  ),
                                )
                              : null,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (_post!.category != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _post!.category!,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Text(
                                _post!.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'By ${_post!.authorName ?? 'Editor'} · ${_formatDate(_post!.publishedAt ?? _post!.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 20),
                              ..._post!.blocks.map((b) => _buildBlock(b, resolver)),
                              const SizedBox(height: 32),
                            ]),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildBlock(BlogContentBlock block, MediaUrlResolver resolver) {
    switch (block.blockType) {
      case 'TEXT':
        if (block.content == null || block.content!.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Html(
            data: block.content!,
            style: {
              'body': Style(margin: Margins.zero, fontSize: FontSize(16), lineHeight: LineHeight(1.6)),
              'p': Style(margin: Margins.only(bottom: 12)),
            },
          ),
        );
      case 'IMAGE':
        final url = resolver.resolvePropertyImageUrl(block.mediaUrl);
        if (url.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              ),
              if (block.caption != null && block.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(block.caption!, style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        );
      case 'LINK':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: block.linkUrl != null ? () => _openUrl(block.linkUrl!) : null,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(block.caption ?? block.linkUrl ?? 'Open link'),
          ),
        );
      case 'VIDEO':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OutlinedButton.icon(
            onPressed: block.mediaUrl != null ? () => _openUrl(block.mediaUrl!) : null,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(block.caption ?? 'Watch video'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
  }
}
