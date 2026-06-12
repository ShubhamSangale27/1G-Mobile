import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/indian_price_formatter.dart';
import '../../../../features/auth/application/auth_controller.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../../../features/property/domain/entities/property.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<SiteVisit> _visits = [];
  List<Property> _recentProperties = [];
  List<AlertItem> _alerts = [];
  int _myPropertiesCount = 0;
  bool _loadingVisits = true;
  bool _loadingProperties = true;
  bool _sendingEmailVerification = false;
  int? _rescheduleVisitId;
  DateTime? _rescheduleDateTime;
  bool _rescheduling = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadVisits(),
      _loadRecentProperties(),
      _loadAlerts(),
    ]);
  }

  Future<void> _loadVisits() async {
    setState(() => _loadingVisits = true);
    try {
      final visits = await ref.read(propertyRepositoryProvider).getMyVisits(page: 0, size: 5);
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _loadingVisits = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVisits = false);
    }
  }

  Future<void> _loadRecentProperties() async {
    setState(() => _loadingProperties = true);
    try {
      final result = await ref.read(propertyRepositoryProvider).getMyProperties(page: 0, size: 5);
      if (!mounted) return;
      setState(() {
        _recentProperties = result.content;
        _myPropertiesCount = result.totalElements;
        _loadingProperties = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProperties = false);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await ref.read(propertyRepositoryProvider).getAlerts(page: 0, size: 10);
      if (!mounted) return;
      setState(() => _alerts = alerts);
    } catch (_) {}
  }

  int get _unreadAlerts => _alerts.where((a) => !a.read).length;

  String _resolveImageUrl(Property property) {
    final images = property.images;
    PropertyImage? image;
    if (images != null) {
      for (final item in images) {
        if (item.mediaType == MediaType.image) {
          image = item;
          break;
        }
      }
    }
    return ref.read(mediaUrlResolverProvider).resolvePropertyImageUrl(image?.imageUrl);
  }

  Future<void> _sendEmailVerification() async {
    setState(() => _sendingEmailVerification = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification link sent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sendingEmailVerification = false);
    }
  }

  Future<void> _submitReschedule(int visitId) async {
    if (_rescheduleDateTime == null) return;
    setState(() => _rescheduling = true);
    try {
      await ref.read(propertyRepositoryProvider).rescheduleVisit(
            visitId,
            _rescheduleDateTime!.toUtc().toIso8601String(),
          );
      if (!mounted) return;
      setState(() {
        _rescheduleVisitId = null;
        _rescheduleDateTime = null;
        _rescheduling = false;
      });
      await _loadVisits();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit rescheduled')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _rescheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  Future<void> _pickRescheduleDateTime() async {
    final now = DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _rescheduleDateTime ?? now,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_rescheduleDateTime ?? now),
    );
    if (time == null) return;
    setState(() {
      _rescheduleDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatVisitDate(String iso) {
    try {
      return DateFormat.yMMMd().add_jm().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _statusLabel(PropertyStatus? status) => switch (status) {
        PropertyStatus.approved => 'APPROVED',
        PropertyStatus.rejected => 'REJECTED',
        PropertyStatus.pendingApproval => 'PENDING APPROVAL',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome back, ${user?.fullName ?? 'User'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your properties",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            if (user != null && !user.emailVerified) ...[
              Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Verify your email', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'We\'ll send a verification link to ${user.email}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _sendingEmailVerification ? null : _sendEmailVerification,
                        child: Text(_sendingEmailVerification ? 'Sending...' : 'Send link'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildVisitsSection(),
            const SizedBox(height: 24),
            _buildRecentPropertiesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.propertyNew),
        icon: const Icon(Icons.add),
        label: const Text('List Property'),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          icon: Icons.home_outlined,
          value: '$_myPropertiesCount',
          label: 'My Properties',
          onTap: () => context.push(RoutePaths.myProperties),
        ),
        _StatCard(
          icon: Icons.event_outlined,
          value: '${_visits.length}',
          label: 'Site Visits',
        ),
        _StatCard(
          icon: Icons.notifications_outlined,
          value: '$_unreadAlerts',
          label: 'Unread Alerts',
        ),
      ],
    );
  }

  Widget _buildVisitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent Site Visits', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(RoutePaths.search),
                  child: const Text('Book New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingVisits)
              ...List.generate(3, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SkeletonLoader(height: 60),
                  ))
            else if (_visits.isEmpty)
              const EmptyView(message: 'No site visits scheduled yet.')
            else
              ..._visits.map(_buildVisitTile),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTile(SiteVisit visit) {
    final canReschedule = visit.canReschedule;
    final isRescheduling = _rescheduleVisitId == visit.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.propertyTitle ?? 'Property #${visit.propertyId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatVisitDate(visit.scheduledAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      visit.status.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              if (canReschedule && !isRescheduling)
                OutlinedButton(
                  onPressed: () => setState(() => _rescheduleVisitId = visit.id),
                  child: const Text('Reschedule'),
                ),
            ],
          ),
          if (isRescheduling) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _rescheduleDateTime != null
                    ? _formatVisitDate(_rescheduleDateTime!.toIso8601String())
                    : 'Pick new date & time',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickRescheduleDateTime,
            ),
            Row(
              children: [
                FilledButton(
                  onPressed: _rescheduling || _rescheduleDateTime == null
                      ? null
                      : () => _submitReschedule(visit.id),
                  child: Text(_rescheduling ? 'Updating...' : 'Confirm'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _rescheduleVisitId = null;
                    _rescheduleDateTime = null;
                  }),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPropertiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('My Recent Properties', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(RoutePaths.myProperties),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingProperties)
              ...List.generate(2, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SkeletonLoader(height: 80),
                  ))
            else if (_recentProperties.isEmpty)
              EmptyView(
                message: 'You haven\'t listed any properties yet.',
                actionLabel: 'List Property',
                onAction: () => context.push(RoutePaths.propertyNew),
              )
            else
              ..._recentProperties.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _resolveImageUrl(p),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${IndianPriceFormatter.format(p.price)} · ${_statusLabel(p.status)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(RoutePaths.propertyEdit(p.id)),
                    ),
                    onTap: () => context.push(RoutePaths.propertyDetail(p.id)),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
