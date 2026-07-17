import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/application_models.dart';
import '../providers/applications_provider.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(applicationStatsProvider);
    final appsAsync = ref.watch(applicationsProvider);
    final statusFilter = ref.watch(applicationsStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Instructor Applications',
            subtitle: 'Review and approve instructor access requests',
          ),
          const SizedBox(height: 24),

          // Stats row
          statsAsync.when(
            data: (s) => _StatsRow(stats: s),
            loading: () => const SizedBox(height: 72),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Filter tabs
          _StatusTabs(
            selected: statusFilter,
            onSelect: (v) => ref
                .read(applicationsStatusFilterProvider.notifier)
                .state = v,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: appsAsync.when(
              data: (apps) {
                if (apps.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_ind_outlined,
                    title: 'No applications',
                    subtitle: 'No instructor applications match this filter.',
                  );
                }
                return _ApplicationsList(
                  applications: apps,
                  onApprove: (a) => _approve(context, ref, a),
                  onReject: (a) => _reject(context, ref, a),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(applicationsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(
      BuildContext ctx, WidgetRef ref, InstructorApplication app) async {
    final ok = await showConfirmDialog(ctx,
        title: 'Approve Application',
        message:
            'Approve ${app.userName} as an instructor? Their role will be updated automatically.',
        confirmLabel: 'Approve');
    if (!ok) return;
    final success =
        await ref.read(applicationsActionProvider.notifier).approve(app.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(success
            ? '${app.userName} approved as instructor.'
            : 'Action failed.'),
      ));
    }
  }

  Future<void> _reject(
      BuildContext ctx, WidgetRef ref, InstructorApplication app) async {
    final reason = await showInputDialog(ctx,
        title: 'Reject Application',
        hint: 'Enter rejection reason…',
        maxLines: 3);
    if (reason == null || reason.trim().isEmpty) return;
    final success = await ref
        .read(applicationsActionProvider.notifier)
        .reject(app.id, reason.trim());
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(success ? 'Application rejected.' : 'Action failed.'),
      ));
    }
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final ApplicationStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Pending', value: stats.pending, color: AppColors.warning),
        const SizedBox(width: 10),
        _StatChip(label: 'Approved', value: stats.approved, color: AppColors.success),
        const SizedBox(width: 10),
        _StatChip(label: 'Rejected', value: stats.rejected, color: AppColors.error),
        const SizedBox(width: 10),
        _StatChip(label: 'Total', value: stats.total, color: AppColors.textSecondary),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.selected, required this.onSelect});
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (v, l) in [
          (null, 'All'),
          ('pending', 'Pending'),
          ('approved', 'Approved'),
          ('rejected', 'Rejected'),
        ])
          GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected == v
                    ? AppColors.primarySurface
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected == v
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(
                l,
                style: TextStyle(
                  color: selected == v
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected == v
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({
    required this.applications,
    required this.onApprove,
    required this.onReject,
  });
  final List<InstructorApplication> applications;
  final void Function(InstructorApplication) onApprove;
  final void Function(InstructorApplication) onReject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ApplicationCard(
        application: applications[i],
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });
  final InstructorApplication application;
  final void Function(InstructorApplication) onApprove;
  final void Function(InstructorApplication) onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = application.status == 'pending';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  Formatters.initials(application.userName),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      application.userEmail,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusBadge.fromStatus(application.status),
              const SizedBox(width: 12),
              Text(
                Formatters.timeAgo(application.createdAt),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          _InfoBlock(title: 'Motivation', text: application.motivation),
          const SizedBox(height: 10),
          _InfoBlock(title: 'Expertise', text: application.expertise),
          if (application.rejectionReason != null) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              title: 'Rejection Reason',
              text: application.rejectionReason!,
              titleColor: AppColors.error,
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => onApprove(application),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => onReject(application),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.text,
    this.titleColor = AppColors.textMuted,
  });
  final String title;
  final String text;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: titleColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
