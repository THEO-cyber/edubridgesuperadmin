import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/report_models.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reportStatsProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final statusFilter = ref.watch(reportsStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Content Reports',
            subtitle: 'Review and resolve user-submitted content reports',
          ),
          const SizedBox(height: 24),

          statsAsync.when(
            data: (s) => _StatsRow(stats: s),
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Filter tabs
          Row(
            children: [
              for (final (v, l) in [
                (null, 'All'),
                ('pending', 'Pending'),
                ('reviewed', 'Reviewed'),
                ('actioned', 'Actioned'),
                ('dismissed', 'Dismissed'),
              ])
                GestureDetector(
                  onTap: () => ref
                      .read(reportsStatusFilterProvider.notifier)
                      .state = v,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: statusFilter == v
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusFilter == v
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      l,
                      style: TextStyle(
                        color: statusFilter == v
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: statusFilter == v
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No reports',
                    subtitle: 'No content reports match this filter.',
                  );
                }
                return ListView.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReportCard(
                    report: reports[i],
                    onResolve: (r) => _showResolveDialog(context, ref, r),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(reportsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(
      BuildContext ctx, WidgetRef ref, ContentReport report) {
    String selectedStatus = 'reviewed';
    final resolutionCtrl = TextEditingController();

    showDialog<void>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          title: const Text('Resolve Report'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select resolution status:',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: selectedStatus,
                  onChanged: (v) => setState(() => selectedStatus = v ?? selectedStatus),
                  child: Column(
                    children: [
                      for (final (v, l) in [
                        ('reviewed', 'Reviewed — noted, no action'),
                        ('actioned', 'Actioned — content removed/suspended'),
                        ('dismissed', 'Dismissed — report unfounded'),
                      ])
                        RadioListTile<String>(
                          value: v,
                          title: Text(l,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13)),
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: resolutionCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Resolution note',
                    hintText: 'Describe the action taken…',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(reportsActionProvider.notifier).resolve(
                      report.id,
                      status: selectedStatus,
                      resolution: resolutionCtrl.text.trim(),
                    );
                resolutionCtrl.dispose();
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Report resolved.')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip('Pending', stats.pending, AppColors.warning),
        const SizedBox(width: 10),
        _Chip('Reviewed', stats.reviewed, AppColors.info),
        const SizedBox(width: 10),
        _Chip('Actioned', stats.actioned, AppColors.success),
        const SizedBox(width: 10),
        _Chip('Total', stats.total, AppColors.textSecondary),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onResolve});
  final ContentReport report;
  final void Function(ContentReport) onResolve;

  static IconData _iconFor(String type) => switch (type) {
        'course' => Icons.school_rounded,
        'review' => Icons.star_rounded,
        'user' => Icons.person_rounded,
        'chat_message' => Icons.chat_rounded,
        'discussion' => Icons.forum_rounded,
        _ => Icons.flag_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isPending = report.status == 'pending';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _iconFor(report.targetType),
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.targetType
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.fromStatus(report.status),
                    const Spacer(),
                    Text(
                      Formatters.timeAgo(report.createdAt),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                if (report.targetTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    report.targetTitle!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  report.reason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reported by ${report.reporterName} (${report.reporterEmail})',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                if (report.resolution != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.resolution!,
                          style: const TextStyle(
                              color: AppColors.success, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: ElevatedButton(
                onPressed: () => onResolve(report),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Text('Resolve'),
              ),
            ),
        ],
      ),
    );
  }
}
