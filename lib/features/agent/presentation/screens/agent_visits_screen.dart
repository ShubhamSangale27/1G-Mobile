import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/agent_repository.dart';
import '../../domain/entities/agent_visit.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

enum _VisitFilter { all, active, completed }

class AgentVisitsScreen extends ConsumerStatefulWidget {
  const AgentVisitsScreen({super.key});

  @override
  ConsumerState<AgentVisitsScreen> createState() => _AgentVisitsScreenState();
}

class _AgentVisitsScreenState extends ConsumerState<AgentVisitsScreen> {
  final _otpControllers = <int, TextEditingController>{};
  _VisitFilter _filter = _VisitFilter.active;
  List<AgentVisitRow> _visits = [];
  int _page = 0;
  int _totalPages = 0;
  int _dueTodayCount = 0;
  bool _loading = true;
  String? _error;
  int? _completingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _otpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(agentRepositoryProvider).getSiteVisits(page: _page);
      if (!mounted) return;
      setState(() {
        _visits = page.content;
        _totalPages = page.totalPages;
        _dueTodayCount = page.dueTodayCount;
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

  List<AgentVisitRow> get _filtered {
    switch (_filter) {
      case _VisitFilter.active:
        return _visits.where((v) => v.isAssigned).toList();
      case _VisitFilter.completed:
        return _visits.where((v) => v.isCompleted).toList();
      case _VisitFilter.all:
        return _visits;
    }
  }

  int get _activeCount => _visits.where((v) => v.isAssigned).length;
  int get _completedCount => _visits.where((v) => v.isCompleted).length;

  TextEditingController _otpFor(int id) =>
      _otpControllers.putIfAbsent(id, TextEditingController.new);

  Future<void> _complete(AgentVisitRow visit) async {
    final otp = _otpFor(visit.id).text.trim();
    if (otp.isEmpty) return;
    setState(() => _completingId = visit.id);
    try {
      await ref.read(agentRepositoryProvider).completeVisit(visit.id, otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit marked complete!')),
      );
      setState(() {
        final idx = _visits.indexWhere((v) => v.id == visit.id);
        if (idx >= 0) _visits[idx] = visit.copyWith(status: 'COMPLETED');
        _otpFor(visit.id).clear();
        _completingId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _completingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  bool _isDueToday(String scheduledAt) {
    final d = DateTime.tryParse(scheduledAt);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Site Visits')),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 0;
          await _load();
        },
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SkeletonLoader(height: 72),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 120),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 120),
                ],
              )
            : _error != null
                ? ListView(
                    children: [
                      ErrorView(message: _error!, onRetry: _load),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Field Operations',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      Text(
                        'Assigned Visits',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the OTP the customer shares in person to complete a visit.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatChip(label: 'Active', value: '$_activeCount'),
                          const SizedBox(width: 8),
                          if (_dueTodayCount > 0)
                            _StatChip(label: 'Due today', value: '$_dueTodayCount', highlight: true),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Done', value: '$_completedCount'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<_VisitFilter>(
                        segments: const [
                          ButtonSegment(value: _VisitFilter.all, label: Text('All')),
                          ButtonSegment(value: _VisitFilter.active, label: Text('Active')),
                          ButtonSegment(value: _VisitFilter.completed, label: Text('Done')),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (s) => setState(() => _filter = s.first),
                      ),
                      const SizedBox(height: 16),
                      if (_filtered.isEmpty)
                        const EmptyView(message: 'No visits in this filter.')
                      else
                        ..._filtered.map((v) => _VisitCard(
                              visit: v,
                              dueToday: _isDueToday(v.scheduledAt),
                              otpController: _otpFor(v.id),
                              completing: _completingId == v.id,
                              onComplete: () => _complete(v),
                              onDetails: () => context.push(RoutePaths.agentVisitDetail(v.id)),
                            )),
                      if (_totalPages > 1) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 0
                                  ? () {
                                      _page--;
                                      _load();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('Page ${_page + 1} of $_totalPages'),
                            IconButton(
                              onPressed: _page < _totalPages - 1
                                  ? () {
                                      _page++;
                                      _load();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: highlight ? AppColors.primary.withValues(alpha: 0.08) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.dueToday,
    required this.otpController,
    required this.completing,
    required this.onComplete,
    required this.onDetails,
  });

  final AgentVisitRow visit;
  final bool dueToday;
  final TextEditingController otpController;
  final bool completing;
  final VoidCallback onComplete;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final scheduled = DateTime.tryParse(visit.scheduledAt);
    final dateLabel = scheduled != null
        ? DateFormat('EEE, MMM d · h:mm a').format(scheduled.toLocal())
        : visit.scheduledAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dueToday && visit.isAssigned
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.propertyTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('📅 $dateLabel', style: Theme.of(context).textTheme.bodySmall),
                _StatusPill(status: visit.status),
                if (dueToday && visit.isAssigned)
                  const _StatusPill(status: 'TODAY', color: AppColors.warning),
              ],
            ),
            if (visit.userName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Customer: ${visit.userName}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (visit.isAssigned) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP from customer',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: completing ? null : onComplete,
                    child: Text(completing ? '…' : 'Complete'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(onPressed: onDetails, child: const Text('Details')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.color});

  final String status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (status == 'COMPLETED'
            ? AppColors.success
            : status == 'ASSIGNED'
                ? AppColors.primary
                : AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}
