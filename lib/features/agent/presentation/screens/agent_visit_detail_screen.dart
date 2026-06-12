import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/indian_price_formatter.dart';
import '../../../../features/property/data/repositories/property_repository.dart';
import '../../data/repositories/agent_repository.dart';
import '../../domain/entities/agent_visit.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/state_views.dart';

class AgentVisitDetailScreen extends ConsumerStatefulWidget {
  const AgentVisitDetailScreen({super.key, required this.visitId});

  final int visitId;

  @override
  ConsumerState<AgentVisitDetailScreen> createState() => _AgentVisitDetailScreenState();
}

class _AgentVisitDetailScreenState extends ConsumerState<AgentVisitDetailScreen> {
  AgentVisitDetail? _detail;
  bool _loading = true;
  String? _error;
  final _otpController = TextEditingController();
  final _commentController = TextEditingController();
  bool _completing = false;
  bool _savingComment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref.read(agentRepositoryProvider).getVisitDetail(widget.visitId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _complete() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _detail == null) return;
    setState(() => _completing = true);
    try {
      await ref.read(agentRepositoryProvider).completeVisit(_detail!.id, otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit marked as done.')),
      );
      setState(() {
        _detail = _detail!.copyWith(status: 'COMPLETED');
        _otpController.clear();
        _completing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _detail == null) return;
    setState(() => _savingComment = true);
    try {
      final comment = await ref.read(agentRepositoryProvider).addComment(_detail!.id, text);
      if (!mounted) return;
      setState(() {
        _detail = _detail!.copyWith(comments: [..._detail!.comments, comment]);
        _commentController.clear();
        _savingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(mediaUrlResolverProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonLoader(height: 200),
            )
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _detail == null
                  ? const EmptyView(message: 'Visit not found.')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _detail!.property.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '📅 ${_formatDate(_detail!.scheduledAt)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                _StatusPill(status: _detail!.status),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Property', style: Theme.of(context).textTheme.titleMedium),
                                if (_detail!.property.firstImageUrl != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: resolver.resolvePropertyImageUrl(
                                        _detail!.property.firstImageUrl,
                                      ),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _InfoRow('Address',
                                    '${_detail!.property.address ?? ''}, ${_detail!.property.city ?? ''} ${_detail!.property.state ?? ''}'),
                                _InfoRow('Type',
                                    '${_detail!.property.propertyType ?? ''} · ${_detail!.property.listingType ?? ''}'),
                                if (_detail!.property.price != null)
                                  _InfoRow('Price', IndianPriceFormatter.format(_detail!.property.price!)),
                                _InfoRow('Beds / Baths / Area',
                                    '${_detail!.property.bedrooms ?? '-'} / ${_detail!.property.bathrooms ?? '-'} / ${_detail!.property.areaSqft ?? '-'} sq ft'),
                                if (_detail!.property.amenities != null &&
                                    _detail!.property.amenities!.isNotEmpty)
                                  _InfoRow('Amenities', _detail!.property.amenities!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 12),
                                _InfoRow('Name', _detail!.userName),
                                InkWell(
                                  onTap: () => _launch(Uri.parse('mailto:${_detail!.userEmail}')),
                                  child: _InfoRow('Email', _detail!.userEmail, link: true),
                                ),
                                InkWell(
                                  onTap: () => _launch(Uri.parse('tel:${_detail!.userMobile}')),
                                  child: _InfoRow('Mobile', _detail!.userMobile, link: true),
                                ),
                                if (_detail!.userNotes != null && _detail!.userNotes!.isNotEmpty)
                                  _InfoRow('Notes', _detail!.userNotes!),
                              ],
                            ),
                          ),
                        ),
                        if (_detail!.status == 'ASSIGNED') ...[
                          const SizedBox(height: 12),
                          Card(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Complete this visit',
                                      style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'The customer received an OTP on their mobile. They must share it with you in person.',
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _otpController,
                                    decoration: const InputDecoration(labelText: '6-digit OTP'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _completing ? null : _complete,
                                    child: Text(_completing ? 'Completing…' : 'Mark visit complete'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Comments (visible to admin)',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 12),
                                if (_detail!.comments.isEmpty)
                                  Text('No comments yet.', style: Theme.of(context).textTheme.bodySmall)
                                else
                                  ..._detail!.comments.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        tileColor: AppColors.background,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        title: Text(c.commentText),
                                        subtitle: Text('${c.userName} · ${_formatShort(c.createdAt)}'),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Add a comment',
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _savingComment ? null : _addComment,
                                  child: Text(_savingComment ? 'Saving…' : 'Add comment'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMEd().add_jm().format(d.toLocal());
  }

  String _formatShort(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('MMM d, h:mm a').format(d.toLocal());
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.link = false});

  final String label;
  final String value;
  final bool link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: link ? AppColors.primary : null,
                fontWeight: link ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'COMPLETED' ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
