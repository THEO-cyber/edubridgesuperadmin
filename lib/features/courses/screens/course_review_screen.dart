import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/course_models.dart';
import '../providers/courses_provider.dart';

void _showVideoDialog(
  BuildContext context,
  String videoId,
  String title,
  String token, {
  String videoStatus = 'READY',
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _VideoPlayerDialog(
      videoId: videoId,
      title: title,
      token: token,
      videoStatus: videoStatus,
    ),
  );
}

class CourseReviewScreen extends ConsumerWidget {
  const CourseReviewScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseReviewProvider(courseId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        String message = e.toString();
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            message = data['message']?.toString() ?? message;
          } else if (data != null) {
            message = data.toString();
          }
          message = '[${e.response?.statusCode}] $message';
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(courseReviewProvider(courseId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      data: (detail) => _ReviewBody(detail: detail),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.detail});
  final CourseReviewDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(coursesActionProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => context.pop(),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${detail.instructorName} · ${detail.categoryName}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                StatusBadge.fromStatus(detail.status),
                const SizedBox(width: 20),
                if (detail.status == 'UNDER_REVIEW') ...[
                  _RejectButton(
                      courseId: detail.id,
                      title: detail.title,
                      busy: busy),
                  const SizedBox(width: 10),
                  _ApproveButton(
                      courseId: detail.id,
                      title: detail.title,
                      busy: busy),
                ],
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: course structure
                Expanded(
                  flex: 3,
                  child: _CourseStructurePanel(detail: detail),
                ),
                const VerticalDivider(
                    width: 1, color: AppColors.border),
                // Right: stats + reviews
                SizedBox(
                  width: 320,
                  child: _SidePanelContent(detail: detail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Left panel: course structure ────────────────────────────────────────────

class _CourseStructurePanel extends StatelessWidget {
  const _CourseStructurePanel({required this.detail});
  final CourseReviewDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              const Text(
                'COURSE STRUCTURE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _StatPill(
                  '${detail.sections.length} sections',
                  AppColors.primary),
              const SizedBox(width: 6),
              _StatPill(
                  '${detail.totalLessons} lessons',
                  AppColors.info),
              if (detail.totalVideos > 0) ...[
                const SizedBox(width: 6),
                _StatPill(
                  '${detail.readyVideos}/${detail.totalVideos} videos ready',
                  detail.readyVideos == detail.totalVideos
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
              if (detail.totalQuizQuestions > 0) ...[
                const SizedBox(width: 6),
                _StatPill(
                    '${detail.totalQuizQuestions} quiz Qs',
                    AppColors.violet),
              ],
            ],
          ),
        ),
        if (detail.description != null && detail.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              detail.description!,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: detail.sections.length,
            itemBuilder: (_, i) =>
                _SectionCard(section: detail.sections[i]),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.section});
  final ReviewSection section;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(10))
                : BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.section.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.section.lessons.length} lessons',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: widget.section.lessons
                    .map((l) => _LessonRow(lesson: l))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonRow extends ConsumerWidget {
  const _LessonRow({required this.lesson});
  final ReviewLesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vs = lesson.videoStatus;
    Color? vsColor;
    IconData vsIcon = Icons.videocam_off_rounded;
    String vsLabel = '';

    if (vs == 'READY') {
      vsColor = AppColors.success;
      vsIcon = Icons.check_circle_rounded;
      vsLabel = 'Ready';
    } else if (vs == 'PROCESSING') {
      vsColor = AppColors.info;
      vsIcon = Icons.sync_rounded;
      vsLabel = 'Processing';
    } else if (vs == 'PENDING') {
      vsColor = AppColors.warning;
      vsIcon = Icons.hourglass_empty_rounded;
      vsLabel = 'Pending';
    } else if (vs == 'PENDING_REVIEW') {
      vsColor = AppColors.amber;
      vsIcon = Icons.rate_review_rounded;
      vsLabel = 'Awaiting review';
    } else if (vs == 'FAILED') {
      vsColor = AppColors.error;
      vsIcon = Icons.error_rounded;
      vsLabel = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 26),
          const Icon(Icons.play_circle_outline_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lesson.title,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lesson.quizCount > 0) ...[
            const SizedBox(width: 8),
            _Chip('${lesson.quizCount} Q', AppColors.violet),
          ],
          if (vs != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: vs == 'FAILED' && lesson.videoError != null
                  ? lesson.videoError!
                  : vsLabel,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(vsIcon, size: 13, color: vsColor),
                  const SizedBox(width: 3),
                  Text(vsLabel,
                      style: TextStyle(
                          color: vsColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          if (lesson.duration != null) ...[
            const SizedBox(width: 10),
            Text(
              _fmtDuration(lesson.duration!),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ],
          if (lesson.videoId != null &&
              (lesson.videoStatus == 'READY' || lesson.videoStatus == 'PENDING_REVIEW')) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: lesson.videoStatus == 'PENDING_REVIEW'
                  ? 'Preview (awaiting review)'
                  : 'Play video',
              child: InkWell(
                onTap: () {
                  final token = ref.read(authProvider).user?.token ?? '';
                  _showVideoDialog(
                    context,
                    lesson.videoId!,
                    lesson.title,
                    token,
                    videoStatus: lesson.videoStatus ?? 'READY',
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.play_circle_rounded,
                    size: 17,
                    color: vs == 'READY'
                        ? AppColors.success
                        : AppColors.amber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }
}

// ─── Right panel: stats + reviews ────────────────────────────────────────────

class _SidePanelContent extends StatelessWidget {
  const _SidePanelContent({required this.detail});
  final CourseReviewDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('COURSE INFO'),
          const SizedBox(height: 10),
          _InfoRow('Instructor', detail.instructorName),
          _InfoRow('Email', detail.instructorEmail),
          _InfoRow('Category', detail.categoryName),
          _InfoRow(
            'Price',
            detail.price == 0 ? 'Free' : Formatters.currency(detail.price),
          ),
          _InfoRow('Submitted', Formatters.date(detail.createdAt)),
          _InfoRow('Enrollments', '${detail.enrollmentCount}'),
          if (detail.avgRating > 0)
            _InfoRow('Avg Rating', '${detail.avgRating.toStringAsFixed(1)} / 5'),
          const SizedBox(height: 20),

          const _SectionLabel('VIDEO STATUS'),
          const SizedBox(height: 10),
          _VideoStatusBar(detail: detail),
          const SizedBox(height: 20),

          if (detail.recentReviews.isNotEmpty) ...[
            const _SectionLabel('RECENT REVIEWS'),
            const SizedBox(height: 10),
            ...detail.recentReviews
                .map((r) => _ReviewCard(review: r)),
          ],
        ],
      ),
    );
  }
}

class _VideoStatusBar extends StatelessWidget {
  const _VideoStatusBar({required this.detail});
  final CourseReviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final total = detail.totalVideos;
    if (total == 0) {
      return const Text('No videos',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }

    final lessons = detail.sections.expand((s) => s.lessons);
    final ready = lessons.where((l) => l.videoStatus == 'READY').length;
    final processing = lessons.where((l) => l.videoStatus == 'PROCESSING').length;
    final pending = lessons.where((l) => l.videoStatus == 'PENDING').length;
    final pendingReview = lessons.where((l) => l.videoStatus == 'PENDING_REVIEW').length;
    final failed = lessons.where((l) => l.videoStatus == 'FAILED').length;

    return Column(
      children: [
        if (ready > 0) _VSRow(Icons.check_circle_rounded, AppColors.success, 'Ready', ready),
        if (processing > 0) _VSRow(Icons.sync_rounded, AppColors.info, 'Processing', processing),
        if (pending > 0) _VSRow(Icons.hourglass_empty_rounded, AppColors.warning, 'Pending', pending),
        if (pendingReview > 0) _VSRow(Icons.rate_review_rounded, AppColors.amber, 'Awaiting review', pendingReview),
        if (failed > 0) _VSRow(Icons.error_rounded, AppColors.error, 'Failed', failed),
      ],
    );
  }
}

class _VSRow extends StatelessWidget {
  const _VSRow(this.icon, this.color, this.label, this.count);
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color, fontSize: 12)),
            const Spacer(),
            Text('$count',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final RecentCourseReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.studentName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 12,
                    color: i < review.rating
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            Formatters.date(review.createdAt),
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Approve / Reject buttons ─────────────────────────────────────────────────

class _ApproveButton extends ConsumerWidget {
  const _ApproveButton(
      {required this.courseId, required this.title, required this.busy});
  final String courseId;
  final String title;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: busy
          ? null
          : () async {
              final ok = await _confirm(context);
              if (!ok || !context.mounted) return;
              final success = await ref
                  .read(coursesActionProvider.notifier)
                  .approve(courseId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? '"$title" approved and is now live.'
                      : 'Approval failed.'),
                ));
                if (success) context.pop();
              }
            },
      icon: const Icon(Icons.check_rounded, size: 16),
      label: const Text('Approve'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Approve Course'),
            content: Text(
                'Publish "$title"? It will go live and the instructor will be notified.'),
            actions: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white),
                child: const Text('Approve'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _RejectButton extends ConsumerWidget {
  const _RejectButton(
      {required this.courseId, required this.title, required this.busy});
  final String courseId;
  final String title;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: busy ? null : () => _showDialog(context, ref),
      icon: const Icon(Icons.close_rounded, size: 16),
      label: const Text('Reject'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Reject Course'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejecting "$title". All course files will be deleted and the instructor will receive your reason.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection',
                    hintText:
                        'e.g. Content is incomplete, please add more lessons…',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: ctrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final reason = ctrl.text.trim();
                      Navigator.pop(dialogCtx);
                      final success = await ref
                          .read(coursesActionProvider.notifier)
                          .reject(courseId, reason);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? '"$title" rejected. Instructor notified.'
                              : 'Rejection failed.'),
                        ));
                        if (success) context.pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12)),
            ),
          ],
        ),
      );
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

// ─── Video player dialog ──────────────────────────────────────────────────────

class _VideoPlayerDialog extends StatefulWidget {
  const _VideoPlayerDialog({
    required this.videoId,
    required this.title,
    required this.token,
    this.videoStatus = 'READY',
  });
  final String videoId;
  final String title;
  final String token;
  final String videoStatus;

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late final Player _player;
  late final VideoController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.stream.error.listen((err) {
      final msg = err.contains('Failed to open')
          ? 'Video file not found in storage.\nThe file may not have been fully processed yet.'
          : err;
      if (mounted) setState(() => _error = msg);
    });
    _fetchAndPlay();
  }

  Future<void> _fetchAndPlay() async {
    try {
      final dio = Dio();
      final isReady = widget.videoStatus == 'READY';
      final apiUrl = isReady
          ? '${ApiEndpoints.baseUrl}${ApiEndpoints.videoStreamUrl(widget.videoId)}'
          : '${ApiEndpoints.baseUrl}${ApiEndpoints.videoPreviewUrl(widget.videoId)}';

      final resp = await dio.get<dynamic>(
        apiUrl,
        options: Options(
          headers: {'Authorization': 'Bearer ${widget.token}'},
          validateStatus: (_) => true,
        ),
      );

      final data = resp.data;

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final msg = (data is Map ? data['message']?.toString() : null)
            ?? 'Server returned ${resp.statusCode}';
        if (mounted) setState(() { _loading = false; _error = msg; });
        return;
      }

      final streamUrl = data is Map ? data['streamUrl']?.toString() : null;
      if (streamUrl == null || streamUrl.isEmpty) {
        if (mounted) setState(() { _loading = false; _error = 'No stream URL returned'; });
        return;
      }

      await _player.open(Media(streamUrl));
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.62).clamp(500.0, 800.0);
    final dialogHeight = dialogWidth * 9 / 16 + 48.0;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Video(
                          controller: _controller,
                          controls: AdaptiveVideoControls,
                        ),
                        if (_loading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
