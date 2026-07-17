import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/video_models.dart';

final videoProcessingRepositoryProvider =
    Provider<VideoProcessingRepository>((ref) {
  return VideoProcessingRepository(ref.read(apiClientProvider));
});

class VideoProcessingRepository {
  VideoProcessingRepository(this._client);
  final ApiClient _client;

  Future<VideoProcessingStats> getStats() async {
    try {
      final res = await _client.get(ApiEndpoints.videoProcessingStats);
      if (res.data is Map<String, dynamic>) {
        return VideoProcessingStats.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return const VideoProcessingStats(pending: 0, processing: 0, ready: 0, failed: 0);
  }

  Future<List<VideoJob>> getFailedJobs() async {
    try {
      final res = await _client.get(
        ApiEndpoints.videoProcessingStats,
        queryParameters: {'status': 'failed'},
      );
      final data = res.data;
      if (data is! Map) return [];
      final list = (data['jobs'] ?? data['data'] ?? []) as List<dynamic>;
      return list
          .map((e) => VideoJob.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> retry(String videoId) =>
      _client.post(ApiEndpoints.retryVideo(videoId));

  Future<List<PendingVideo>> getPendingVideos() async {
    final res = await _client.get(ApiEndpoints.pendingVideos);
    final data = res.data;
    final list = (data is List ? data : data['videos'] ?? data['data'] ?? []) as List<dynamic>;
    return list.map((e) => PendingVideo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String?> getPreviewUrl(String videoId, {String quality = '720p'}) async {
    try {
      final res = await _client.get(ApiEndpoints.videoPreviewUrl(videoId, quality: quality));
      if (res.data is Map) {
        return (res.data as Map)['streamUrl']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<void> approveVideo(String videoId) =>
      _client.post(ApiEndpoints.approveVideo(videoId));

  Future<void> rejectVideo(String videoId, String reason) =>
      _client.post(ApiEndpoints.rejectVideo(videoId), data: {'reason': reason});
}
