import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/route_paths.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../features/blog/data/repositories/blog_repository.dart';
import '../../../../features/blog/domain/entities/blog_post.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/blog_card.dart';
import '../../../../shared/widgets/listing_type_toggle.dart';
import '../../../../shared/widgets/property_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _searchController = TextEditingController();
  final _carouselController = PageController();
  Timer? _carouselTimer;

  bool _searchTypeBuy = true;
  List<CarouselSlide> _slides = [];
  List<Property> _featured = [];
  List<BlogPost> _blogs = [];
  bool _loadingCarousel = true;
  bool _loadingFeatured = true;
  bool _loadingBlogs = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final hasData = _featured.isNotEmpty || _slides.isNotEmpty;
    if (!hasData || forceRefresh) {
      setState(() {
        _loadingCarousel = _slides.isEmpty;
        _loadingFeatured = _featured.isEmpty;
        _loadingBlogs = _blogs.isEmpty;
        _error = null;
      });
    }
    final propertyRepo = ref.read(propertyRepositoryProvider);
    final blogRepo = ref.read(blogRepositoryProvider);
    try {
      final results = await Future.wait([
        propertyRepo.getCarouselSlides(forceRefresh: forceRefresh),
        propertyRepo.getFeatured(forceRefresh: forceRefresh),
        blogRepo.getPublished(size: 6, forceRefresh: forceRefresh),
      ]);
      if (!mounted) return;
      final slides = results[0] as List<CarouselSlide>;
      setState(() {
        _slides = slides.where((s) => s.active).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _featured = results[1] as List<Property>;
        _blogs = results[2] as List<BlogPost>;
        _loadingCarousel = false;
        _loadingFeatured = false;
        _loadingBlogs = false;
      });
      _startCarouselAutoPlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMapper.toUserMessage(e);
        _loadingCarousel = false;
        _loadingFeatured = false;
        _loadingBlogs = false;
      });
    }
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    if (_slides.length <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_carouselController.hasClients) return;
      final current = _carouselController.page?.round() ?? 0;
      final next = (current + 1) % _slides.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToSearch({String? listingType}) {
    AppNavigation.openSearch(
      context,
      city: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      listingType: listingType ?? (_searchTypeBuy ? 'SALE' : 'RENT'),
    );
  }

  void _selectBuy() {
    setState(() => _searchTypeBuy = true);
    _goToSearch(listingType: 'SALE');
  }

  void _selectRent() {
    setState(() => _searchTypeBuy = false);
    _goToSearch(listingType: 'RENT');
  }

  String _resolveSlideUrl(String url) =>
      ref.read(mediaUrlResolverProvider).resolvePropertyImageUrl(url);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              toolbarHeight: 60,
              titleSpacing: 8,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              title: const AppLogo(
                size: AppLogoSize.compact,
                maxHeight: 48,
              ),
              actions: [
                IconButton(
                  tooltip: 'Blog',
                  onPressed: () => AppNavigation.go(context, RoutePaths.blog),
                  icon: const Icon(Icons.menu_book_outlined),
                ),
              ],
            ),
            SliverToBoxAdapter(child: _buildHeroSearch()),
            if (_loadingCarousel)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SkeletonLoader(height: 160, borderRadius: 16),
                ),
              )
            else if (_slides.isNotEmpty)
              SliverToBoxAdapter(child: _buildCarousel()),
            if (_error != null && _featured.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(message: _error!, onRetry: _loadData),
              )
            else ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Featured Properties',
                  subtitle: 'Handpicked listings for you',
                  actionLabel: 'See all',
                  onAction: () => _goToSearch(),
                ),
              ),
              if (_loadingFeatured)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Responsive.featuredStripHeight(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, __) => SkeletonLoader(
                        width: Responsive.horizontalCardWidth(context),
                        height: Responsive.featuredStripHeight(context),
                        borderRadius: 16,
                      ),
                    ),
                  ),
                )
              else if (_featured.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyView(message: 'No featured properties right now.'),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Responsive.featuredStripHeight(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: _featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        height: Responsive.featuredStripHeight(context) - 8,
                        width: Responsive.horizontalCardWidth(context),
                        child: PropertyGridCard(
                          property: _featured[index],
                          width: Responsive.horizontalCardWidth(context),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Property Insights',
                  subtitle: 'Guides, tips & market updates',
                  actionLabel: 'All articles',
                  onAction: () => AppNavigation.go(context, RoutePaths.blog),
                ),
              ),
              if (_loadingBlogs)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Responsive.blogCompactStripHeight(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, __) => SkeletonLoader(
                        width: 240,
                        height: Responsive.blogCompactStripHeight(context),
                        borderRadius: 16,
                      ),
                    ),
                  ),
                )
              else if (_blogs.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Responsive.blogCompactStripHeight(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _blogs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => BlogCard(post: _blogs[index], compact: true),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              PageView.builder(
                controller: _carouselController,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return CachedNetworkImage(
                    imageUrl: _resolveSlideUrl(slide.imageUrl),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => const SkeletonLoader(height: 160),
                    errorWidget: (_, __, ___) => Container(color: AppColors.border),
                  );
                },
              ),
              if (_slides.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedBuilder(
                        animation: _carouselController,
                        builder: (context, _) {
                          final page = _carouselController.hasClients
                              ? (_carouselController.page ?? 0).round()
                              : 0;
                          return Container(
                            width: page == i ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: page == i ? Colors.white : Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A6E), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your dream home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search thousands of verified listings across India',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ListingTypeToggle(
            selectedBuy: _searchTypeBuy,
            onBuy: _selectBuy,
            onRent: _selectRent,
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'City, locality or project',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _goToSearch(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilledButton(
                    onPressed: () => _goToSearch(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
