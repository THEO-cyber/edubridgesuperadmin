import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/course_models.dart';
import '../providers/courses_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(coursesFilterProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Course Moderation',
            subtitle: 'Review, approve, reject and suspend courses',
          ),
          const SizedBox(height: 24),

          // Status tabs
          _StatusTabs(
            selected: filter.status,
            onSelect: (s) => ref
                .read(coursesFilterProvider.notifier)
                .update((f) => f.copyWith(
                    status: s, page: 1, clearStatus: s == null)),
          ),
          const SizedBox(height: 16),

          // Search
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref
                      .read(coursesFilterProvider.notifier)
                      .update((f) => f.copyWith(
                          search: v,
                          page: 1,
                          clearSearch: v.isEmpty)),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search by title…',
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 16, color: AppColors.textMuted),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(coursesProvider),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No courses found',
                      subtitle: 'Try a different filter or status tab.',
                    );
                  }
                  return _CoursesTable(
                    courses: courses,
                    onApprove: (c) => _approve(context, ref, c),
                    onReject: (c) => _reject(context, ref, c),
                    onSuspend: (c) => _suspend(context, ref, c),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(coursesProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext ctx, WidgetRef ref, AdminCourse c) async {
    final ok = await showConfirmDialog(ctx,
        title: 'Approve Course',
        message: 'Publish "${c.title}"? It will become visible to students.',
        confirmLabel: 'Approve');
    if (!ok) return;
    final success =
        await ref.read(coursesActionProvider.notifier).approve(c.id);
    if (ctx.mounted) {
      _snack(ctx, success ? '"${c.title}" approved.' : 'Action failed.');
    }
  }

  Future<void> _reject(BuildContext ctx, WidgetRef ref, AdminCourse c) async {
    final reason = await showInputDialog(ctx,
        title: 'Reject Course',
        hint: 'Enter rejection reason…',
        maxLines: 3);
    if (reason == null || reason.trim().isEmpty) return;
    final success = await ref
        .read(coursesActionProvider.notifier)
        .reject(c.id, reason.trim());
    if (ctx.mounted) {
      _snack(ctx, success ? '"${c.title}" rejected.' : 'Action failed.');
    }
  }

  Future<void> _suspend(BuildContext ctx, WidgetRef ref, AdminCourse c) async {
    final reason = await showInputDialog(ctx,
        title: 'Suspend Course',
        hint: 'Enter suspension reason…',
        maxLines: 3);
    if (reason == null || reason.trim().isEmpty) return;
    final success = await ref
        .read(coursesActionProvider.notifier)
        .suspend(c.id, reason.trim());
    if (ctx.mounted) {
      _snack(ctx, success ? '"${c.title}" suspended.' : 'Action failed.');
    }
  }

  void _snack(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}

// ─── Status Tabs ─────────────────────────────────────────────────────────────

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.selected, required this.onSelect});
  final String? selected;
  final void Function(String?) onSelect;

  static const _tabs = [
    (null, 'All'),
    ('UNDER_REVIEW', 'Under Review'),
    ('PUBLISHED', 'Published'),
    ('DRAFT', 'Draft'),
    ('REJECTED', 'Rejected'),
    ('SUSPENDED', 'Suspended'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final (value, label) = tab;
          final isActive = selected == value;
          return GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primarySurface
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isActive ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Courses Table ────────────────────────────────────────────────────────────

class _CoursesTable extends StatelessWidget {
  const _CoursesTable({
    required this.courses,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  });

  final List<AdminCourse> courses;
  final void Function(AdminCourse) onApprove;
  final void Function(AdminCourse) onReject;
  final void Function(AdminCourse) onSuspend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: const Row(
            children: [
              _TH('Course', flex: 4),
              _TH('Instructor', flex: 2),
              _TH('Category', flex: 2),
              _TH('Status', flex: 2),
              _TH('Price', flex: 1),
              _TH('Actions', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: courses.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _CourseRow(
              course: courses[i],
              onApprove: onApprove,
              onReject: onReject,
              onSuspend: onSuspend,
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.course,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  });

  final AdminCourse course;
  final void Function(AdminCourse) onApprove;
  final void Function(AdminCourse) onReject;
  final void Function(AdminCourse) onSuspend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Created ${Formatters.date(course.createdAt)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.instructorName,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(course.instructorEmail,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(course.categoryName,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge.fromStatus(course.status),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              course.price == 0
                  ? 'Free'
                  : Formatters.currency(course.price),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (course.status == 'UNDER_REVIEW') ...[
                  _Btn(
                    icon: Icons.rate_review_rounded,
                    color: AppColors.primary,
                    tooltip: 'Review',
                    onTap: () => context.push('/courses/${course.id}'),
                  ),
                  const SizedBox(width: 4),
                  _Btn(
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    tooltip: 'Approve',
                    onTap: () => onApprove(course),
                  ),
                  const SizedBox(width: 4),
                  _Btn(
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    tooltip: 'Reject',
                    onTap: () => onReject(course),
                  ),
                ],
                if (course.status == 'PUBLISHED') ...[
                  const SizedBox(width: 4),
                  _Btn(
                    icon: Icons.pause_circle_outline_rounded,
                    color: AppColors.warning,
                    tooltip: 'Suspend',
                    onTap: () => onSuspend(course),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );
}
