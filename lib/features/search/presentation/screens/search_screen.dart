import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/indian_locations.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/indian_price_formatter.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/property_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

const _priceRangeMin = 0;
const _priceRangeMax = 500000000;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCity, this.initialListingType});

  final String? initialCity;
  final String? initialListingType;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin {
  final _cityController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _scrollController = ScrollController();

  String _state = '';
  String _city = '';
  String _listingType = '';
  String _propertyType = '';
  double _priceSliderMin = _priceRangeMin.toDouble();
  double _priceSliderMax = _priceRangeMax.toDouble();
  int? _bedrooms;

  String _sortBy = 'createdAt,desc';
  int _page = 0;
  final List<Property> _properties = [];
  int _totalPages = 0;
  int _totalElements = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _searched = false;
  String? _error;
  List<String> _citiesForState = [];
  String? _lastQueryKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRoute());
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minAreaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  String _queryKey(GoRouterState state) =>
      '${state.uri.queryParameters}';

  void _syncFromRoute() {
    if (!mounted) return;
    final state = GoRouterState.of(context);
    final key = _queryKey(state);
    if (key == _lastQueryKey && _searched) return;

    final params = state.uri.queryParameters;
    setState(() {
      _state = params['state'] ?? '';
      _city = params['city'] ?? widget.initialCity ?? '';
      _listingType = params['listingType'] ?? widget.initialListingType ?? '';
      _propertyType = params['propertyType'] ?? '';
      _cityController.text = _city;
      _citiesForState = _state.isNotEmpty ? IndianLocations.citiesForState(_state) : [];
      _lastQueryKey = key;
    });
    _search(reset: true);
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRoute());
  }

  num? get _minPrice {
    if (_priceSliderMin == _priceRangeMin && _priceSliderMax == _priceRangeMax) return null;
    return _priceSliderMin.round();
  }

  num? get _maxPrice {
    if (_priceSliderMin == _priceRangeMin && _priceSliderMax == _priceRangeMax) return null;
    return _priceSliderMax.round();
  }

  int get _activeFilterCount {
    var n = 0;
    if (_listingType.isNotEmpty) n++;
    if (_propertyType.isNotEmpty) n++;
    if (_state.isNotEmpty) n++;
    if (_city.isNotEmpty) n++;
    if (_minPrice != null || _maxPrice != null) n++;
    if (_bedrooms != null) n++;
    if (_minAreaController.text.trim().isNotEmpty) n++;
    return n;
  }

  Future<void> _search({bool reset = true, bool forceRefresh = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _properties.clear();
        _loading = true;
        _error = null;
        _searched = true;
      });
    } else {
      if (_loadingMore || _loading) return;
      setState(() => _loadingMore = true);
    }

    final parts = _sortBy.split(',');
    final params = PropertySearchParams(
      page: _page,
      size: 12,
      sort: parts.first,
      direction: parts.length > 1 ? parts[1] : 'desc',
      city: _city.isNotEmpty ? _city : null,
      listingType: _listingType.isNotEmpty ? _listingType : null,
      propertyType: _propertyType.isNotEmpty ? _propertyType : null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      bedrooms: _bedrooms,
      minArea: num.tryParse(_minAreaController.text.trim()),
    );

    try {
      final result = await ref.read(propertyRepositoryProvider).search(
            params,
            forceRefresh: forceRefresh || reset,
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
        _totalElements = result.totalElements;
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
    if (_page >= _totalPages - 1 || _loadingMore || _loading) return;
    _page++;
    _search(reset: false);
  }

  void _setListingType(String type) {
    setState(() => _listingType = _listingType == type ? '' : type);
    _search(reset: true);
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        state: _state,
        city: _city,
        listingType: _listingType,
        propertyType: _propertyType,
        priceMin: _priceSliderMin,
        priceMax: _priceSliderMax,
        bedrooms: _bedrooms,
        minAreaController: _minAreaController,
        citiesForState: _citiesForState,
        onApply: (result) {
          setState(() {
            _state = result.state;
            _city = result.city;
            _cityController.text = result.city;
            _listingType = result.listingType;
            _propertyType = result.propertyType;
            _priceSliderMin = result.priceMin;
            _priceSliderMax = result.priceMax;
            _bedrooms = result.bedrooms;
            _citiesForState = _state.isNotEmpty ? IndianLocations.citiesForState(_state) : [];
          });
          _search(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildQuickFilters(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Properties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'City or locality',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) {
                    setState(() => _city = v.trim());
                    _search(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  setState(() => _city = _cityController.text.trim());
                  _search(reset: true);
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ActionChip(
              avatar: Icon(
                Icons.tune,
                size: 18,
                color: _activeFilterCount > 0 ? AppColors.primary : AppColors.textMuted,
              ),
              label: Text(_activeFilterCount > 0 ? 'Filters ($_activeFilterCount)' : 'Filters'),
              onPressed: _openFilters,
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.border),
            ),
            const SizedBox(width: 8),
            _QuickChip(label: 'Buy', selected: _listingType == 'SALE', onTap: () => _setListingType('SALE')),
            _QuickChip(label: 'Rent', selected: _listingType == 'RENT', onTap: () => _setListingType('RENT')),
            if (_propertyType.isNotEmpty)
              _QuickChip(label: _propertyType, selected: true, onTap: _openFilters),
            if (_bedrooms != null)
              _QuickChip(label: '${_bedrooms!}+ BHK', selected: true, onTap: _openFilters),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonLoader(height: 136, borderRadius: 16),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: ErrorView(message: _error!, onRetry: () => _search(reset: true)),
          ),
        ],
      );
    }

    if (_properties.isEmpty && _searched) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: const EmptyView(message: 'No properties match your filters.'),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _search(reset: true, forceRefresh: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _properties.length + 1 + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    _searched ? '$_totalElements properties' : 'Search properties',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'createdAt,desc', child: Text('Newest')),
                    DropdownMenuItem(value: 'price,asc', child: Text('Price ↑')),
                    DropdownMenuItem(value: 'price,desc', child: Text('Price ↓')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sortBy = v);
                    _search(reset: true);
                  },
                ),
              ],
            );
          }
          if (_loadingMore && index == _properties.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PropertyListCard(property: _properties[index - 1]);
        },
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.selected, required this.onTap});

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
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FilterResult {
  _FilterResult({
    required this.state,
    required this.city,
    required this.listingType,
    required this.propertyType,
    required this.priceMin,
    required this.priceMax,
    required this.bedrooms,
  });

  final String state;
  final String city;
  final String listingType;
  final String propertyType;
  final double priceMin;
  final double priceMax;
  final int? bedrooms;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.state,
    required this.city,
    required this.listingType,
    required this.propertyType,
    required this.priceMin,
    required this.priceMax,
    required this.bedrooms,
    required this.minAreaController,
    required this.citiesForState,
    required this.onApply,
  });

  final String state;
  final String city;
  final String listingType;
  final String propertyType;
  final double priceMin;
  final double priceMax;
  final int? bedrooms;
  final TextEditingController minAreaController;
  final List<String> citiesForState;
  final void Function(_FilterResult result) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _state;
  late String _city;
  late String _listingType;
  late String _propertyType;
  late double _priceMin;
  late double _priceMax;
  late int? _bedrooms;
  late List<String> _cities;

  @override
  void initState() {
    super.initState();
    _state = widget.state;
    _city = widget.city;
    _listingType = widget.listingType;
    _propertyType = widget.propertyType;
    _priceMin = widget.priceMin;
    _priceMax = widget.priceMax;
    _bedrooms = widget.bedrooms;
    _cities = widget.citiesForState;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Text('Listing Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _listingType.isEmpty,
                  onSelected: (_) => setState(() => _listingType = ''),
                ),
                ChoiceChip(
                  label: const Text('Buy'),
                  selected: _listingType == 'SALE',
                  onSelected: (_) => setState(() => _listingType = 'SALE'),
                ),
                ChoiceChip(
                  label: const Text('Rent'),
                  selected: _listingType == 'RENT',
                  onSelected: (_) => setState(() => _listingType = 'RENT'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _propertyType.isEmpty ? null : _propertyType,
              decoration: const InputDecoration(labelText: 'Property Type'),
              items: const [
                DropdownMenuItem(value: 'HOUSE', child: Text('House')),
                DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment')),
                DropdownMenuItem(value: 'LAND', child: Text('Land')),
                DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial')),
              ],
              onChanged: (v) => setState(() => _propertyType = v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _state.isEmpty ? null : _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: IndianLocations.stateNames
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _state = v ?? '';
                  _city = '';
                  _cities = _state.isNotEmpty ? IndianLocations.citiesForState(_state) : [];
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _city.isEmpty ? null : _city,
              decoration: const InputDecoration(labelText: 'City'),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v ?? ''),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: ${IndianPriceFormatter.formatLabel(_priceMin)} – ${IndianPriceFormatter.formatLabel(_priceMax)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            RangeSlider(
              min: _priceRangeMin.toDouble(),
              max: _priceRangeMax.toDouble(),
              divisions: 100,
              values: RangeValues(_priceMin, _priceMax),
              onChanged: (v) => setState(() {
                _priceMin = v.start;
                _priceMax = v.end;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _bedrooms,
              decoration: const InputDecoration(labelText: 'Bedrooms (min)'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 1, child: Text('1+')),
                DropdownMenuItem(value: 2, child: Text('2+')),
                DropdownMenuItem(value: 3, child: Text('3+')),
                DropdownMenuItem(value: 4, child: Text('4+')),
              ],
              onChanged: (v) => setState(() => _bedrooms = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.minAreaController,
              decoration: const InputDecoration(
                labelText: 'Min Area (sq.ft)',
                hintText: 'Minimum area',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _state = '';
                        _city = '';
                        _listingType = '';
                        _propertyType = '';
                        _priceMin = _priceRangeMin.toDouble();
                        _priceMax = _priceRangeMax.toDouble();
                        _bedrooms = null;
                        widget.minAreaController.clear();
                        _cities = [];
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_FilterResult(
                        state: _state,
                        city: _city,
                        listingType: _listingType,
                        propertyType: _propertyType,
                        priceMin: _priceMin,
                        priceMax: _priceMax,
                        bedrooms: _bedrooms,
                      ));
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
