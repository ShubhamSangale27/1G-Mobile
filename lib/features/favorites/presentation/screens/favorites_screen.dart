import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/application/auth_controller.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/property_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with AutomaticKeepAliveClientMixin {
  List<Property> _properties = [];
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
    if (!ref.read(isLoggedInProvider)) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _properties = [];
        _error = null;
      });
      return;
    }

    if (_properties.isEmpty || forceRefresh) {
      setState(() {
        _loading = _properties.isEmpty;
        _error = null;
      });
    }

    try {
      final list = await ref.read(propertyRepositoryProvider).getWatchlist(
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      setState(() {
        _properties = list;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (next && previous != next) {
        _load();
      }
    });

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Saved Properties'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        body: EmptyView(
          message: 'Sign in to view your saved properties.',
          actionLabel: 'Login',
          onAction: () => context.push(RoutePaths.login),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Properties'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _loading
          ? ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonLoader(height: 136, borderRadius: 16),
            )
          : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: ErrorView(message: _error!, onRetry: _load),
                    ),
                  ],
                )
              : _properties.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: const EmptyView(message: 'No saved properties yet.'),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(forceRefresh: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _properties.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => PropertyListCard(
                          property: _properties[index],
                        ),
                      ),
                    ),
    );
  }
}
