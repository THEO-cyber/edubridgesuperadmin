import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/video_models.dart';
import '../providers/video_processing_provider.dart';

class VideoProcessingScreen extends ConsumerStatefulWidget {
  const VideoProcessingScreen({super.key});

  @override
  ConsumerState<VideoProcessingScreen> createState() =>
      _VideoProcessingScreenState();
}

class _VideoProcessingScreenState extends ConsumerState<VideoProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Video Management',
            subtitle: 'Review pending videos and monitor transcoding jobs',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(pendingVideosProvider);
                  ref.invalidate(videoStatsProvider);
                  ref.invalidate(videoJobsProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TabBar(
            controller: _tabs,
            isScrollable: false,
            dividerColor: AppColors.border,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: _PendingTabLabel(
                  pendingAsync: ref.watch(pendingVideosProvider),
                ),
              ),
              const Tab(text: 'Processing Stats'),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PendingTab(),
                _StatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab label with live badge count ─────────────────────────────────────────

class _PendingTabLabel extends StatelessWidget {
  const _PendingTabLabel({required this.pendingAsync});
  final AsyncValue<List<PendingVideo>> pendingAsync;

  @override
  Widget build(BuildContext context) {
    final count = pendingAsync.valueOrNull?.length ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Pending Review'),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Pending Review Tab ───────────────────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(pendingVideosProvider);

    return videosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(pendingVideosProvider),
      ),
      data: (videos) {
        if (videos.isEmpty) {
          return const EmptyState(
            icon: Icons.video_library_outlined,
            title: 'No pending videos',
            subtitle: 'All uploaded videos have been reviewed.',
          );
        }
        return ListView.separated(
          itemCount: videos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _PendingVideoCard(video: videos[i]),
        );
      },
    );
  }
}

// ─── Pending Video Card ───────────────────────────────────────────────────────

class _PendingVideoCard extends ConsumerWidget {
  const _PendingVideoCard({required this.video});
  final PendingVideo video;

  String _formatBytes(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(int? secs) {
    if (secs == null) return '—';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 140,
              height: 90,
              color: AppColors.surfaceVariant,
              child: video.thumbnailUrl != null
                  ? Image.network(
                      video.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
          ),
          const SizedBox(width: 20),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filename
                Text(
                  video.filename,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Course → Section → Lesson breadcrumb
                Text(
                  '${video.courseTitle}  ›  ${video.sectionTitle}  ›  ${video.lessonTitle}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Meta row
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _MetaItem(Icons.person_rounded, video.instructorName),
                    _MetaItem(Icons.email_rounded, video.instructorEmail),
                    _MetaItem(Icons.timer_rounded, _formatDuration(video.duration)),
                    _MetaItem(Icons.storage_rounded, _formatBytes(video.fileSize)),
                    _MetaItem(Icons.schedule_rounded,
                        'Uploaded ${Formatters.date(video.createdAt)}'),
                  ],
                ),
                const SizedBox(height: 10),

                // Quality variants
                if (video.variants.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: video.variants.map((v) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          v.quality,
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Actions
          Column(
            children: [
              _PreviewButton(videoId: video.id, title: video.filename),
              const SizedBox(height: 8),
              _ApproveButton(videoId: video.id, filename: video.filename),
              const SizedBox(height: 8),
              _RejectButton(videoId: video.id, filename: video.filename),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => const Center(
        child: Icon(Icons.videocam_rounded,
            color: AppColors.textMuted, size: 36),
      );
}

class _MetaItem extends StatelessWidget {
  const _MetaItem(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}

// ─── Preview button ───────────────────────────────────────────────────────────

class _PreviewButton extends ConsumerWidget {
  const _PreviewButton({required this.videoId, required this.title});
  final String videoId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 110,
      child: OutlinedButton.icon(
        onPressed: () {
          final token = ref.read(authProvider).user?.token ?? '';
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (_) => _VideoPreviewDialog(
              videoId: videoId,
              title: title,
              token: token,
            ),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 14),
        label: const Text('Preview'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _VideoPreviewDialog extends StatefulWidget {
  const _VideoPreviewDialog({
    required this.videoId,
    required this.title,
    required this.token,
  });
  final String videoId;
  final String title;
  final String token;

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
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
      final apiUrl =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.videoPreviewUrl(widget.videoId)}';
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Admin Preview',
                        style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
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

// ─── Approve / Reject buttons ─────────────────────────────────────────────────

class _ApproveButton extends ConsumerWidget {
  const _ApproveButton({required this.videoId, required this.filename});
  final String videoId;
  final String filename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(videoModerationProvider).isLoading;
    return SizedBox(
      width: 110,
      child: ElevatedButton.icon(
        onPressed: busy
            ? null
            : () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Approve Video',
                  message:
                      'Approve "$filename"? It will go live immediately and the instructor will be notified.',
                  confirmLabel: 'Approve',
                );
                if (!ok || !context.mounted) return;
                final success = await ref
                    .read(videoModerationProvider.notifier)
                    .approve(videoId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        success ? 'Video approved and live.' : 'Approval failed.'),
                  ));
                }
              },
        icon: const Icon(Icons.check_rounded, size: 14),
        label: const Text('Approve'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RejectButton extends ConsumerWidget {
  const _RejectButton({required this.videoId, required this.filename});
  final String videoId;
  final String filename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(videoModerationProvider).isLoading;
    return SizedBox(
      width: 110,
      child: OutlinedButton.icon(
        onPressed: busy
            ? null
            : () => _showRejectDialog(context, ref),
        icon: const Icon(Icons.close_rounded, size: 14),
        label: const Text('Reject'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Reject Video'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejecting "$filename". The instructor will be notified with your reason and all transcoded files will be deleted.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection',
                    hintText: 'e.g. Video quality is too low…',
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
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final reason = reasonCtrl.text.trim();
                      Navigator.pop(dialogCtx);
                      final success = await ref
                          .read(videoModerationProvider.notifier)
                          .reject(videoId, reason);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Video rejected. Instructor notified.'
                              : 'Rejection failed.'),
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(videoStatsProvider);
    final jobsAsync = ref.watch(videoJobsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statsAsync.when(
          data: (s) => Row(
            children: [
              Expanded(child: _StatCard('Pending', s.pending, AppColors.warning, Icons.hourglass_empty_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Processing', s.processing, AppColors.info, Icons.sync_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Ready', s.ready, AppColors.success, Icons.check_circle_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Failed', s.failed, AppColors.error, Icons.error_rounded)),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                height: 100,
                child: _DonutChart(stats: s),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 100),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        const Text(
          'FAILED JOBS',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: jobsAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'No failed jobs',
                  subtitle: 'All video processing jobs are healthy.',
                );
              }
              return _JobsList(
                jobs: jobs,
                onRetry: (j) async {
                  final ok =
                      await ref.read(videoRetryProvider.notifier).retry(j.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Retry queued for "${j.title}".'
                          : 'Retry failed.'),
                    ));
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(videoJobsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.color, this.icon);
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Formatters.number(value),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.stats});
  final VideoProcessingStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.total;
    if (total == 0) return const SizedBox.shrink();
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: [
          if (stats.ready > 0)
            PieChartSectionData(
                value: stats.ready.toDouble(),
                color: AppColors.success,
                radius: 20,
                showTitle: false),
          if (stats.processing > 0)
            PieChartSectionData(
                value: stats.processing.toDouble(),
                color: AppColors.info,
                radius: 20,
                showTitle: false),
          if (stats.pending > 0)
            PieChartSectionData(
                value: stats.pending.toDouble(),
                color: AppColors.warning,
                radius: 20,
                showTitle: false),
          if (stats.failed > 0)
            PieChartSectionData(
                value: stats.failed.toDouble(),
                color: AppColors.error,
                radius: 20,
                showTitle: false),
        ],
      ),
    );
  }
}

// ─── Failed jobs list ─────────────────────────────────────────────────────────

class _JobsList extends StatelessWidget {
  const _JobsList({required this.jobs, required this.onRetry});
  final List<VideoJob> jobs;
  final void Function(VideoJob) onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: const Row(
              children: [
                _TH('Video', flex: 4),
                _TH('Status', flex: 2),
                _TH('Error', flex: 4),
                _TH('Date', flex: 2),
                _TH('', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: jobs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) => _JobRow(job: jobs[i], onRetry: onRetry),
            ),
          ),
        ],
      ),
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
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
      );
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.onRetry});
  final VideoJob job;
  final void Function(VideoJob) onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: AppColors.error, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(job.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusBadge.fromStatus(job.status),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              job.errorMessage ?? '—',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(Formatters.date(job.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: 'Retry',
              child: InkWell(
                onTap: () => onRetry(job),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.replay_rounded,
                      size: 16, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
