import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/blog_card.dart';
import '../../../../shared/widgets/blog_hero_header.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/repositories/blog_repository.dart';
import '../../domain/entities/blog_post.dart';

class BlogListScreen extends ConsumerStatefulWidget {
  const BlogListScreen({super.key});

  @override
  ConsumerState<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends ConsumerState<BlogListScreen> with AutomaticKeepAliveClientMixin {
  List<BlogPost> _posts = [];
  BlogFilters _filters = const BlogFilters();
  String _category = '';
  String _tag = '';
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (_posts.isEmpty || forceRefresh) {
      setState(() {
        _loading = _posts.isEmpty;
        _error = null;
      });
    }
    try {
      final repo = ref.read(blogRepositoryProvider);
      final posts = await repo.getPublished(
        category: _category.isEmpty ? null : _category,
        tag: _tag.isEmpty ? null : _tag,
        forceRefresh: forceRefresh,
      );
      BlogFilters filters = _filters;
      try {
        filters = await repo.getFilters();
      } catch (_) {
        // Filters are optional — posts still render.
      }
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _filters = filters;
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

  String? get _heroCover {
    for (final post in _posts) {
      final url = post.coverImageUrl;
      if (url != null && url.trim().isNotEmpty) return url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            BlogHeroHeader(coverImageUrl: _heroCover),
            if (_filters.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _category.isEmpty && _tag.isEmpty,
                        onTap: () {
                          setState(() {
                            _category = '';
                            _tag = '';
                          });
                          _load(forceRefresh: true);
                        },
                      ),
                      ..._filters.categories.map(
                        (c) => _FilterChip(
                          label: c,
                          selected: _category == c,
                          onTap: () {
                            setState(() {
                              _category = c;
                              _tag = '';
                            });
                            _load(forceRefresh: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ShimmerBox(height: 220, borderRadius: 16),
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(message: _error!, onRetry: () => _load(forceRefresh: true)),
              )
            else if (_posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(message: 'No articles published yet.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => BlogCard(post: _posts[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
