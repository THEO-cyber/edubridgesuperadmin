import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_models.dart';
import '../repositories/video_processing_repository.dart';

final videoStatsProvider =
    FutureProvider.autoDispose<VideoProcessingStats>((ref) async {
  // Derive counts from the pending list — the /admin/stats endpoint doesn't exist yet.
  // Falls back to the repo call if the pending list also fails.
  try {
    final pending = await ref.read(videoProcessingRepositoryProvider).getPendingVideos();
    return VideoProcessingStats(
      pending: pending.length,
      processing: 0,
      ready: 0,
      failed: 0,
    );
  } catch (_) {
    return ref.read(videoProcessingRepositoryProvider).getStats();
  }
});

final videoJobsProvider =
    FutureProvider.autoDispose<List<VideoJob>>((ref) async {
  return ref.read(videoProcessingRepositoryProvider).getFailedJobs();
});

class VideoRetryNotifier extends StateNotifier<AsyncValue<void>> {
  VideoRetryNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final VideoProcessingRepository _repo;
  final Ref _ref;

  Future<bool> retry(String videoId) async {
    state = const AsyncLoading();
    try {
      await _repo.retry(videoId);
      _ref.invalidate(videoStatsProvider);
      _ref.invalidate(videoJobsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final videoRetryProvider =
    StateNotifierProvider<VideoRetryNotifier, AsyncValue<void>>((ref) {
  return VideoRetryNotifier(ref.read(videoProcessingRepositoryProvider), ref);
});

final pendingVideosProvider =
    FutureProvider.autoDispose<List<PendingVideo>>((ref) async {
  return ref.read(videoProcessingRepositoryProvider).getPendingVideos();
});

class VideoModerationNotifier extends StateNotifier<AsyncValue<void>> {
  VideoModerationNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final VideoProcessingRepository _repo;
  final Ref _ref;

  void _invalidate() {
    _ref.invalidate(pendingVideosProvider);
    _ref.invalidate(videoStatsProvider);
  }

  Future<bool> approve(String videoId) async {
    state = const AsyncLoading();
    try {
      await _repo.approveVideo(videoId);
      _invalidate();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> reject(String videoId, String reason) async {
    state = const AsyncLoading();
    try {
      await _repo.rejectVideo(videoId, reason);
      _invalidate();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final videoModerationProvider =
    StateNotifierProvider<VideoModerationNotifier, AsyncValue<void>>((ref) {
  return VideoModerationNotifier(ref.read(videoProcessingRepositoryProvider), ref);
});
