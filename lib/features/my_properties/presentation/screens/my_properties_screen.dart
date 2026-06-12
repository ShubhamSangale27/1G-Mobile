import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../config/route_paths.dart';

import '../../../../core/error/error_mapper.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/responsive.dart';

import '../../../../features/property/data/repositories/property_repository.dart';

import '../../../../features/property/domain/entities/property.dart';

import '../../../../shared/widgets/property_card.dart';

import '../../../../shared/widgets/skeleton_loader.dart';

import '../../../../shared/widgets/state_views.dart';



class MyPropertiesScreen extends ConsumerStatefulWidget {

  const MyPropertiesScreen({super.key});



  @override

  ConsumerState<MyPropertiesScreen> createState() => _MyPropertiesScreenState();

}



class _MyPropertiesScreenState extends ConsumerState<MyPropertiesScreen> {

  final List<Property> _properties = [];

  int _page = 0;

  int _totalPages = 0;

  bool _loading = true;

  bool _loadingMore = false;

  bool _deleting = false;

  String? _error;



  @override

  void initState() {

    super.initState();

    _load(reset: true);

  }



  Future<void> _load({required bool reset}) async {

    if (reset) {

      setState(() {

        _page = 0;

        _loading = true;

        _error = null;

      });

    } else {

      setState(() => _loadingMore = true);

    }

    try {

      final result = await ref.read(propertyRepositoryProvider).getMyProperties(

            page: _page,

            size: 12,

          );

      if (!mounted) return;

      setState(() {

        if (reset) {

          _properties

            ..clear()

            ..addAll(result.content);

        } else {

          _properties.addAll(result.content);

        }

        _totalPages = result.totalPages;

        _loading = false;

        _loadingMore = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _error = ErrorMapper.toUserMessage(e);

        _loading = false;

        _loadingMore = false;

      });

    }

  }



  void _loadMore() {

    if (_page >= _totalPages - 1 || _loadingMore) return;

    setState(() => _page++);

    _load(reset: false);

  }



  String _statusLabel(PropertyStatus? status) => switch (status) {

        PropertyStatus.approved => 'Approved',

        PropertyStatus.rejected => 'Rejected',

        PropertyStatus.pendingApproval => 'Pending Approval',

        _ => '',

      };



  Color _statusColor(PropertyStatus? status) => switch (status) {

        PropertyStatus.approved => AppColors.success,

        PropertyStatus.rejected => AppColors.danger,

        PropertyStatus.pendingApproval => AppColors.warning,

        _ => AppColors.textMuted,

      };



  Future<void> _deleteProperty(int id) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Delete Property'),

        content: const Text('Are you sure you want to delete this listing?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

          FilledButton(

            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),

            onPressed: () => Navigator.pop(ctx, true),

            child: const Text('Delete'),

          ),

        ],

      ),

    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    try {

      await ref.read(propertyRepositoryProvider).delete(id);

      if (!mounted) return;

      setState(() {

        _properties.removeWhere((p) => p.id == id);

        _deleting = false;

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Property deleted')),

      );

    } catch (e) {

      if (!mounted) return;

      setState(() => _deleting = false);

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),

      );

    }

  }



  Widget _buildActions(Property property) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(

        color: AppColors.surface,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.border),

      ),

      child: Row(

        children: [

          Flexible(

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              decoration: BoxDecoration(

                color: _statusColor(property.status).withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(999),

              ),

              child: Text(

                _statusLabel(property.status),

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(

                  fontSize: 11,

                  fontWeight: FontWeight.w600,

                  color: _statusColor(property.status),

                  height: 1.1,

                ),

              ),

            ),

          ),

          IconButton(

            visualDensity: VisualDensity.compact,

            icon: const Icon(Icons.edit_outlined, size: 20),

            onPressed: () => context.push(RoutePaths.propertyEdit(property.id)),

            tooltip: 'Edit',

          ),

          IconButton(

            visualDensity: VisualDensity.compact,

            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),

            onPressed: _deleting ? null : () => _deleteProperty(property.id),

            tooltip: 'Delete',

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final padding = Responsive.screenPadding(context);

    final useGrid = Responsive.isTablet(context);



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        title: const Text('My Properties'),

        backgroundColor: AppColors.surface,

        foregroundColor: AppColors.textPrimary,

      ),

      floatingActionButton: FloatingActionButton.extended(

        onPressed: () => context.push(RoutePaths.propertyNew),

        icon: const Icon(Icons.add),

        label: const Text('List New'),

      ),

      body: _loading

          ? ListView.separated(

              padding: padding,

              itemCount: 4,

              separatorBuilder: (_, __) => const SizedBox(height: 12),

              itemBuilder: (_, __) => const SkeletonLoader(height: 148, borderRadius: 12),

            )

          : _error != null

              ? ErrorView(message: _error!, onRetry: () => _load(reset: true))

              : _properties.isEmpty

                  ? EmptyView(

                      message: 'No properties listed yet.',

                      actionLabel: 'List Property',

                      onAction: () => context.push(RoutePaths.propertyNew),

                    )

                  : RefreshIndicator(

                      onRefresh: () => _load(reset: true),

                      child: useGrid

                          ? LayoutBuilder(

                              builder: (context, constraints) {

                                final cols = Responsive.gridCrossAxisCount(context, phone: 2);

                                return CustomScrollView(

                                  slivers: [

                                    SliverPadding(

                                      padding: padding,

                                      sliver: SliverGrid(

                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                                          crossAxisCount: cols,

                                          childAspectRatio: Responsive.gridChildAspectRatio(context),

                                          crossAxisSpacing: 12,

                                          mainAxisSpacing: 12,

                                        ),

                                        delegate: SliverChildBuilderDelegate(

                                          (context, index) {

                                            final property = _properties[index];

                                            return Column(

                                              crossAxisAlignment: CrossAxisAlignment.stretch,

                                              children: [

                                                Expanded(

                                                  child: SizedBox(

                                                    height: double.infinity,

                                                    child: PropertyGridCard(property: property),

                                                  ),

                                                ),

                                                const SizedBox(height: 6),

                                                _buildActions(property),

                                              ],

                                            );

                                          },

                                          childCount: _properties.length,

                                        ),

                                      ),

                                    ),

                                    if (_page < _totalPages - 1) _loadMoreSliver(),

                                  ],

                                );

                              },

                            )

                          : ListView.separated(

                              padding: EdgeInsets.fromLTRB(

                                padding.left,

                                padding.top,

                                padding.right,

                                padding.bottom + 80,

                              ),

                              itemCount: _properties.length + (_page < _totalPages - 1 ? 1 : 0),

                              separatorBuilder: (_, __) => const SizedBox(height: 12),

                              itemBuilder: (context, index) {

                                if (index >= _properties.length) {

                                  return Center(

                                    child: _loadingMore

                                        ? const Padding(

                                            padding: EdgeInsets.all(16),

                                            child: CircularProgressIndicator(),

                                          )

                                        : OutlinedButton(

                                            onPressed: _loadMore,

                                            child: const Text('Load More'),

                                          ),

                                  );

                                }

                                final property = _properties[index];

                                return Column(

                                  crossAxisAlignment: CrossAxisAlignment.stretch,

                                  children: [

                                    PropertyListCard(property: property),

                                    const SizedBox(height: 6),

                                    _buildActions(property),

                                  ],

                                );

                              },

                            ),

                    ),

    );

  }



  Widget _loadMoreSliver() {

    return SliverToBoxAdapter(

      child: Center(

        child: Padding(

          padding: const EdgeInsets.only(bottom: 80),

          child: _loadingMore

              ? const CircularProgressIndicator()

              : OutlinedButton(

                  onPressed: _loadMore,

                  child: const Text('Load More'),

                ),

        ),

      ),

    );

  }

}


