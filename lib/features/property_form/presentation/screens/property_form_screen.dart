import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/indian_locations.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final int? propertyId;

  bool get isEdit => propertyId != null;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _MediaDraft {
  _MediaDraft({required this.imageUrl, required this.mediaType});

  final String imageUrl;
  final MediaType mediaType;
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _localityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _newMediaUrlController = TextEditingController();

  ListingType _listingType = ListingType.sale;
  PropertyType _propertyType = PropertyType.house;
  String _state = '';
  String _city = '';
  MediaType _newMediaType = MediaType.image;
  final List<_MediaDraft> _mediaItems = [];

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  List<String> _citiesForState = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadProperty();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _pincodeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _amenitiesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _newMediaUrlController.dispose();
    super.dispose();
  }

  MediaUrlResolver get _resolver => ref.read(mediaUrlResolverProvider);

  Future<void> _loadProperty() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final property = await ref.read(propertyRepositoryProvider).getById(widget.propertyId!);
      if (!mounted) return;
      _populateFromProperty(property);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMapper.toUserMessage(e);
        _loading = false;
      });
    }
  }

  void _populateFromProperty(Property property) {
    _titleController.text = property.title;
    _descriptionController.text = property.description ?? '';
    _priceController.text = property.price.toString();
    _addressController.text = property.address;
    _localityController.text = property.locality ?? '';
    _pincodeController.text = property.pincode ?? '';
    _bedroomsController.text = property.bedrooms?.toString() ?? '';
    _bathroomsController.text = property.bathrooms?.toString() ?? '';
    _areaController.text = property.areaSqft?.toString() ?? '';
    _amenitiesController.text = property.amenities ?? '';
    _latitudeController.text = property.latitude?.toString() ?? '';
    _longitudeController.text = property.longitude?.toString() ?? '';
    _listingType = property.listingType;
    _propertyType = property.propertyType;
    _state = property.state ?? '';
    _city = property.city ?? '';
    _citiesForState = _state.isNotEmpty ? IndianLocations.citiesForState(_state) : [];
    _mediaItems
      ..clear()
      ..addAll(
        (property.images ?? []).map(
          (img) => _MediaDraft(imageUrl: img.imageUrl, mediaType: img.mediaType),
        ),
      );
  }

  void _onStateChange(String? value) {
    setState(() {
      _state = value ?? '';
      _city = '';
      _citiesForState = _state.isNotEmpty ? IndianLocations.citiesForState(_state) : [];
    });
  }

  void _addMediaByUrl() {
    final url = _newMediaUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a media URL')),
      );
      return;
    }
    if (_newMediaType == MediaType.image) {
      if (!_resolver.isAllowedImageUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image URL. Use http(s) or Google Drive.')),
        );
        return;
      }
    } else {
      if (!_resolver.isAllowedVideoUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid video URL. Use YouTube or Google Drive.')),
        );
        return;
      }
    }
    setState(() {
      _mediaItems.add(_MediaDraft(imageUrl: url, mediaType: _newMediaType));
      _newMediaUrlController.clear();
    });
  }

  void _removeMedia(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  Map<String, dynamic> _buildPayload() {
    final property = Property(
      id: widget.propertyId ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      listingType: _listingType,
      propertyType: _propertyType,
      price: double.parse(_priceController.text.trim()),
      address: _addressController.text.trim(),
      locality: _localityController.text.trim().isEmpty ? null : _localityController.text.trim(),
      city: _city,
      state: _state,
      pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      bedrooms: int.tryParse(_bedroomsController.text.trim()),
      bathrooms: int.tryParse(_bathroomsController.text.trim()),
      areaSqft: double.tryParse(_areaController.text.trim()),
      amenities: _amenitiesController.text.trim().isEmpty ? null : _amenitiesController.text.trim(),
      images: _mediaItems
          .asMap()
          .entries
          .map(
            (e) => PropertyImage(
              imageUrl: e.value.imageUrl,
              mediaType: e.value.mediaType,
              displayOrder: e.key,
            ),
          )
          .toList(),
    );
    return property.toCreateJson();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_state.isEmpty || _city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select state and city')),
      );
      return;
    }
    setState(() => _submitting = true);
    final repo = ref.read(propertyRepositoryProvider);
    final payload = _buildPayload();
    try {
      if (widget.isEdit) {
        await repo.update(widget.propertyId!, payload);
      } else {
        await repo.create(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdit ? 'Property updated' : 'Property listed')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _previewUrl(_MediaDraft media) {
    if (media.mediaType == MediaType.video) {
      return _resolver.resolveVideoPoster(media.imageUrl) ??
          _resolver.resolvePropertyImageUrl(media.imageUrl);
    }
    return _resolver.resolvePropertyImageUrl(media.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEdit ? 'Edit Property' : 'List Property')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(height: 400),
        ),
      );
    }

    if (_error != null && widget.isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Property')),
        body: ErrorView(message: _error!, onRetry: _loadProperty),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Property' : 'List Your Property'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.isEdit ? 'Update your property details' : 'Reach thousands of potential buyers on 1Guntha',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Basic Information'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Property Title *'),
              validator: (v) => Validators.required(v, 'Title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ListingType>(
              value: _listingType,
              decoration: const InputDecoration(labelText: 'Listing Type *'),
              items: const [
                DropdownMenuItem(value: ListingType.sale, child: Text('For Sale')),
                DropdownMenuItem(value: ListingType.rent, child: Text('For Rent')),
              ],
              onChanged: (v) => setState(() => _listingType = v ?? ListingType.sale),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PropertyType>(
              value: _propertyType,
              decoration: const InputDecoration(labelText: 'Property Type *'),
              items: const [
                DropdownMenuItem(value: PropertyType.house, child: Text('House')),
                DropdownMenuItem(value: PropertyType.apartment, child: Text('Apartment')),
                DropdownMenuItem(value: PropertyType.land, child: Text('Land')),
                DropdownMenuItem(value: PropertyType.commercial, child: Text('Commercial')),
              ],
              onChanged: (v) => setState(() => _propertyType = v ?? PropertyType.house),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (₹) *'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionTitle('Location'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address *'),
              validator: (v) => Validators.required(v, 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _localityController,
              decoration: const InputDecoration(labelText: 'Locality'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _state.isEmpty ? null : _state,
              decoration: const InputDecoration(labelText: 'State *'),
              items: IndianLocations.stateNames
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _onStateChange,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _city.isEmpty ? null : _city,
              decoration: const InputDecoration(labelText: 'City *'),
              items: _citiesForState
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Specifications'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    decoration: const InputDecoration(labelText: 'Bedrooms'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(labelText: 'Bathrooms'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area (sq.ft)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amenitiesController,
              decoration: const InputDecoration(
                labelText: 'Amenities (comma-separated)',
                hintText: 'Parking, Gym, Security',
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Property Media (URL only)'),
            Text(
              'Paste a public image URL, Google Drive image link, or YouTube video URL.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _newMediaUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Media URL',
                      hintText: 'Google Drive or YouTube URL',
                    ),
                    onSubmitted: (_) => _addMediaByUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<MediaType>(
                    value: _newMediaType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: MediaType.image, child: Text('Image')),
                      DropdownMenuItem(value: MediaType.video, child: Text('Video')),
                    ],
                    onChanged: (v) => setState(() => _newMediaType = v ?? MediaType.image),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(onPressed: _addMediaByUrl, child: const Text('Add URL')),
            ),
            if (_mediaItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${_mediaItems.length} media item(s) added'),
              const SizedBox(height: 8),
              ..._mediaItems.asMap().entries.map((entry) {
                final i = entry.key;
                final media = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: _previewUrl(media),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      media.imageUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(media.mediaType == MediaType.video ? 'VIDEO' : 'IMAGE'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.danger),
                      onPressed: () => _removeMedia(i),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting
                          ? 'Saving...'
                          : widget.isEdit
                              ? 'Update Property'
                              : 'List Property',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
