import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/page_header.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final activity = ref.watch(activityProvider);
    final trends = ref.watch(enrollmentTrendsProvider);
    final instructors = ref.watch(topInstructorsProvider);
    final categories = ref.watch(categoryStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Platform overview and key metrics',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(activityProvider);
                  ref.invalidate(enrollmentTrendsProvider);
                  ref.invalidate(topInstructorsProvider);
                  ref.invalidate(categoryStatsProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // KPI Cards
          stats.when(
            data: (s) => _KpiGrid(stats: s),
            loading: () => _KpiGridSkeleton(),
            error: (e, _) => _SectionError('Stats unavailable', e.toString()),
          ),
          const SizedBox(height: 24),

          // Charts row: enrollment trend + activity feed
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _EnrollmentChart(trendsAsync: trends),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _ActivityFeed(activityAsync: activity),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Second row: category distribution + pending actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _CategoryChart(categoriesAsync: categories),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: stats.when(
                  data: (s) => _PendingActionsPanel(stats: s),
                  loading: () => const SizedBox(height: 220),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top instructors
          _TopInstructorsTable(instructorsAsync: instructors),
        ],
      ),
    );
  }
}

// ─── KPI Cards ────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Total Users',
            value: Formatters.number(stats.totalUsers),
            sub: '${Formatters.number(stats.instructorCount)} instructors',
            icon: Icons.people_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Published Courses',
            value: Formatters.number(stats.totalCourses),
            sub: '${stats.pendingReview} pending review',
            icon: Icons.school_rounded,
            color: AppColors.violet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Total Enrollments',
            value: Formatters.number(stats.totalEnrollments),
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Total Revenue',
            value: Formatters.currency(stats.totalRevenue),
            icon: Icons.attach_money_rounded,
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.sub,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _KpiGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (_) => Expanded(
          child: Container(
            height: 130,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Enrollment Chart ────────────────────────────────────────────────────────

class _EnrollmentChart extends StatelessWidget {
  const _EnrollmentChart({required this.trendsAsync});
  final AsyncValue<List<EnrollmentTrendPoint>> trendsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enrollment Trends',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '30-day enrollment activity',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: trendsAsync.when(
              data: (points) {
                if (points.isEmpty) {
                  return const Center(
                    child: Text('No data',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return _LineChartWidget(points: points);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Could not load trends',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({required this.points});
  final List<EnrollmentTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    final maxY = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(
                Formatters.compact(v),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: points.length > 7 ? (points.length / 6).roundToDouble() : 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                try {
                  final dt = DateTime.parse(points[i].date);
                  return Text(
                    DateFormat('M/d').format(dt),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
      ),
    );
  }
}

// ─── Activity Feed ────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.activityAsync});
  final AsyncValue<List<ActivityEvent>> activityAsync;

  static IconData _iconFor(String type) => switch (type) {
        'user_registered' => Icons.person_add_rounded,
        'course_created' => Icons.add_box_rounded,
        'user_enrolled' => Icons.school_rounded,
        'course_approved' => Icons.check_circle_rounded,
        'course_rejected' => Icons.cancel_rounded,
        'payout_processed' => Icons.payments_rounded,
        _ => Icons.circle_notifications_rounded,
      };

  static Color _colorFor(String type) => switch (type) {
        'user_registered' => AppColors.info,
        'course_created' => AppColors.violet,
        'user_enrolled' => AppColors.success,
        'course_approved' => AppColors.success,
        'course_rejected' => AppColors.error,
        'payout_processed' => AppColors.amber,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Recent Activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Latest platform events',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: activityAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Text('No activity yet',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = events[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _colorFor(e.type).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconFor(e.type),
                              color: _colorFor(e.type),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.description,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.timeAgo(e.timestamp),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Could not load activity',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Instructors ─────────────────────────────────────────────────────────

class _TopInstructorsTable extends StatelessWidget {
  const _TopInstructorsTable({required this.instructorsAsync});
  final AsyncValue<List<TopInstructor>> instructorsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Top Instructors',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Ranked by total revenue',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          instructorsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No instructor data',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              return _InstructorTable(instructors: list);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Could not load instructors',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorTable extends StatelessWidget {
  const _InstructorTable({required this.instructors});
  final List<TopInstructor> instructors;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          children: ['#', 'Instructor', 'Revenue', 'Courses', 'Students']
              .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ))
              .toList(),
        ),
        ...instructors.take(8).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final inst = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.transparent : AppColors.background.withValues(alpha: 0.3),
              border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        Formatters.initials(inst.name),
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inst.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          Text(inst.email,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  Formatters.currency(inst.revenue),
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  Formatters.number(inst.courseCount),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  Formatters.number(inst.studentCount),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Category Distribution Chart ─────────────────────────────────────────────

class _CategoryChart extends StatefulWidget {
  const _CategoryChart({required this.categoriesAsync});
  final AsyncValue<List<CategoryStat>> categoriesAsync;

  @override
  State<_CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<_CategoryChart> {
  int? _touchedIndex;

  static const _colors = [
    AppColors.primary,
    AppColors.success,
    AppColors.amber,
    AppColors.violet,
    AppColors.info,
    AppColors.rose,
    AppColors.cyan,
    AppColors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Courses per category',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: widget.categoriesAsync.when(
              data: (cats) {
                if (cats.isEmpty) {
                  return const Center(
                    child: Text('No category data',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                final total = cats.fold<int>(0, (s, c) => s + c.count);
                return Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                _touchedIndex = response
                                    ?.touchedSection?.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: cats.take(8).toList().asMap().entries.map((e) {
                            final isTouched = _touchedIndex == e.key;
                            final color = _colors[e.key % _colors.length];
                            return PieChartSectionData(
                              value: e.value.count.toDouble(),
                              color: color,
                              radius: isTouched ? 28 : 22,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cats.take(6).toList().asMap().entries.map((e) {
                          final color = _colors[e.key % _colors.length];
                          final pct = total > 0
                              ? (e.value.count / total * 100).toStringAsFixed(0)
                              : '0';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.value.name,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Could not load categories',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending Actions Panel ────────────────────────────────────────────────────

class _PendingActionsPanel extends StatelessWidget {
  const _PendingActionsPanel({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pending Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Items requiring your attention',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _PendingRow(
            icon: Icons.school_rounded,
            color: AppColors.violet,
            label: 'Courses under review',
            count: stats.pendingReview,
            hint: stats.pendingReview == 0 ? 'None pending' : null,
          ),
          const SizedBox(height: 6),
          const _PendingRow(
            icon: Icons.assignment_ind_rounded,
            color: AppColors.amber,
            label: 'Instructor applications',
            count: 0,
            hint: 'See Applications page',
          ),
          const SizedBox(height: 6),
          const _PendingRow(
            icon: Icons.flag_rounded,
            color: AppColors.error,
            label: 'Content reports',
            count: 0,
            hint: 'See Reports page',
          ),
          const SizedBox(height: 6),
          const _PendingRow(
            icon: Icons.videocam_rounded,
            color: AppColors.rose,
            label: 'Failed video jobs',
            count: 0,
            hint: 'See Video Processing',
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    this.hint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0
            ? color.withValues(alpha: 0.06)
            : AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0 ? color.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: count > 0 ? color : AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: count > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: count > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              hint ?? 'None pending',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError(this.title, this.message);
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}


