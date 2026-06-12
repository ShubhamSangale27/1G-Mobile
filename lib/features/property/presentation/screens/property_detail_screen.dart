import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/indian_price_formatter.dart';
import '../../../../core/utils/property_gallery.dart';
import '../../../../shared/widgets/property_thumbnail.dart';
import '../../../../shared/widgets/property_video_embed.dart';
import '../../../../features/auth/application/auth_controller.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  Property? _property;
  SiteVisit? _myVisit;
  bool _inWatchlist = false;
  String? _visitOtp;
  bool _visitOtpExpired = false;
  bool _loading = true;
  bool _watchlistLoading = false;
  bool _booking = false;
  bool _rescheduling = false;
  bool _resendingOtp = false;
  String? _error;
  final _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(propertyRepositoryProvider);
    try {
      final property = await repo.getById(widget.propertyId);
      SiteVisit? visit;
      bool inWatchlist = false;
      String? otp;
      var otpExpired = false;
      if (ref.read(isLoggedInProvider)) {
        visit = await repo.getMyVisitForProperty(widget.propertyId);
        inWatchlist = await repo.isInWatchlist(widget.propertyId);
        if (visit != null && visit.isAssigned) {
          try {
            otp = await repo.getVisitOtp(visit.id);
          } catch (e) {
            final message = ErrorMapper.toUserMessage(e).toLowerCase();
            if (message.contains('otp expired') || message.contains('resend')) {
              otpExpired = true;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _property = property;
        _myVisit = visit;
        _inWatchlist = inWatchlist;
        _visitOtp = otp;
        _visitOtpExpired = otpExpired;
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

  List<GallerySlide> get _gallerySlides => buildGallerySlides(_property?.images);

  Future<void> _toggleWatchlist() async {
    if (!ref.read(isLoggedInProvider)) {
      context.push(RoutePaths.login);
      return;
    }
    setState(() => _watchlistLoading = true);
    final repo = ref.read(propertyRepositoryProvider);
    try {
      if (_inWatchlist) {
        await repo.removeFromWatchlist(widget.propertyId);
      } else {
        await repo.addToWatchlist(widget.propertyId);
      }
      if (!mounted) return;
      setState(() {
        _inWatchlist = !_inWatchlist;
        _watchlistLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _watchlistLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  Future<void> _bookVisit() async {
    if (!ref.read(isLoggedInProvider)) {
      context.push(RoutePaths.login);
      return;
    }
    final booking = await _showDateTimeDialog(title: 'Book Site Visit', notesField: true);
    if (booking == null) return;
    setState(() => _booking = true);
    try {
      final visit = await ref.read(propertyRepositoryProvider).bookVisit(
            propertyId: widget.propertyId,
            scheduledAt: booking.scheduledAt,
            userNotes: booking.notes,
          );
      if (!mounted) return;
      setState(() {
        _myVisit = visit;
        _booking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site visit booked successfully')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  Future<void> _rescheduleVisit() async {
    if (_myVisit == null) return;
    final booking = await _showDateTimeDialog(title: 'Reschedule Site Visit');
    if (booking == null) return;
    setState(() => _rescheduling = true);
    try {
      final visit = await ref.read(propertyRepositoryProvider).rescheduleVisit(
            _myVisit!.id,
            booking.scheduledAt,
          );
      if (!mounted) return;
      setState(() {
        _myVisit = visit;
        _rescheduling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit rescheduled')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _rescheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_myVisit == null) return;
    setState(() => _resendingOtp = true);
    try {
      final otp = await ref.read(propertyRepositoryProvider).resendVisitOtp(_myVisit!.id);
      if (!mounted) return;
      setState(() {
        _visitOtp = otp;
        _visitOtpExpired = false;
        _resendingOtp = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _resendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  Future<({String scheduledAt, String? notes})?> _showDateTimeDialog({
    required String title,
    bool notesField = false,
  }) async {
    DateTime selected = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();
    final result = await showDialog<({String scheduledAt, String? notes})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(selected)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selected,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selected = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selected.hour,
                          selected.minute,
                        ));
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(DateFormat.jm().format(selected)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(selected),
                  );
                  if (time != null) {
                    setDialogState(() => selected = DateTime(
                          selected.year,
                          selected.month,
                          selected.day,
                          time.hour,
                          time.minute,
                        ));
                  }
                },
              ),
              if (notesField) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any special requirements...',
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (
                scheduledAt: selected.toUtc().toIso8601String(),
                notes: notesField && notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
              )),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    notesController.dispose();
    return result;
  }

  String _formatVisitDate(String iso) {
    try {
      return DateFormat.yMMMd().add_jm().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(height: 240, borderRadius: 12),
              SizedBox(height: 16),
              SkeletonLoader(height: 120),
            ],
          ),
        ),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property')),
        body: ErrorView(
          message: _error ?? 'Property not found',
          onRetry: _load,
        ),
      );
    }

    final property = _property!;
    final gallery = _gallerySlides;
    final resolver = ref.watch(mediaUrlResolverProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (ref.watch(isLoggedInProvider))
            IconButton(
              onPressed: _watchlistLoading ? null : _toggleWatchlist,
              icon: Icon(
                _inWatchlist ? Icons.favorite : Icons.favorite_border,
                color: _inWatchlist ? AppColors.danger : null,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              child: gallery.isEmpty
                  ? PropertyThumbnail(imageUrl: '', width: double.infinity, height: 260, fit: BoxFit.cover)
                  : PageView.builder(
                      controller: _galleryController,
                      onPageChanged: (i) => setState(() => _galleryIndex = i),
                      itemCount: gallery.length,
                      itemBuilder: (_, i) {
                        final slide = gallery[i];
                        if (slide.kind == GallerySlideKind.videoEmbed && slide.embedPlayUrl != null) {
                          return PropertyVideoEmbed(
                            sourceUrl: slide.sourceUrl,
                            embedUrl: slide.embedPlayUrl!,
                            posterUrl: resolver.resolveVideoPoster(slide.sourceUrl),
                          );
                        }
                        return PropertyThumbnail(
                          imageUrl: resolver.resolvePropertyImageUrl(slide.sourceUrl),
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
            ),
            if (gallery.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    '${_galleryIndex + 1} / ${gallery.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: gallery.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final slide = gallery[i];
                    final isVideo = slide.kind == GallerySlideKind.videoEmbed;
                    final thumbUrl = isVideo
                        ? resolver.resolveVideoPoster(slide.sourceUrl) ?? ''
                        : resolver.resolvePropertyImageUrl(slide.sourceUrl);
                    return GestureDetector(
                      onTap: () {
                        _galleryController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _galleryIndex == i ? AppColors.primary : AppColors.border,
                            width: _galleryIndex == i ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PropertyThumbnail(
                          imageUrl: thumbUrl,
                          showVideoBadge: isVideo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    IndianPriceFormatter.format(property.price),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    property.listingType == ListingType.rent ? 'per month' : 'total price',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${property.address}, ${property.city ?? ''}${property.state != null ? ', ${property.state}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (property.bedrooms != null) Chip(label: Text('${property.bedrooms} BHK')),
                      if (property.bathrooms != null) Chip(label: Text('${property.bathrooms} Bath')),
                      if (property.areaSqft != null) Chip(label: Text('${property.areaSqft!.round()} sq.ft')),
                      Chip(label: Text(property.propertyType.name.toUpperCase())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVisitSection(),
                  if (property.description != null && property.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Description', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(property.description!),
                  ],
                  if (property.amenitiesList.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenitiesList
                          .map((a) => Chip(
                                avatar: const Icon(Icons.check, size: 16, color: AppColors.success),
                                label: Text(a),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitSection() {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Site Visit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!isLoggedIn)
              FilledButton(
                onPressed: () => context.push(RoutePaths.login),
                child: const Text('Login to Book Visit'),
              )
            else if (_myVisit == null)
              FilledButton(
                onPressed: _booking ? null : _bookVisit,
                child: _booking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Book Site Visit'),
              )
            else ...[
              Row(
                children: [
                  Chip(
                    label: Text(_myVisit!.status.replaceAll('_', ' ')),
                    backgroundColor: _myVisit!.isAssigned
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatVisitDate(_myVisit!.scheduledAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (_myVisit!.isAssigned &&
                  ((_visitOtp != null && _visitOtp!.isNotEmpty) || _visitOtpExpired)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Visit OTP', style: Theme.of(context).textTheme.labelLarge),
                      if (_visitOtp != null && _visitOtp!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _visitOtp!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share this OTP with the agent only in person when the visit is finished.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Your OTP has expired. Tap resend to get a new one.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _resendingOtp ? null : _resendOtp,
                        child: Text(_resendingOtp ? 'Sending...' : 'Resend OTP'),
                      ),
                    ],
                  ),
                ),
              ],
              if (_myVisit!.canReschedule) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _rescheduling ? null : _rescheduleVisit,
                  child: Text(_rescheduling ? 'Rescheduling...' : 'Reschedule Visit'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
