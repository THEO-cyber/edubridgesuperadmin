import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(apiClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._client);
  final ApiClient _client;

  Future<DashboardStats> getStats() async {
    final res = await _client.get(ApiEndpoints.dashboardStats);
    return DashboardStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActivityEvent>> getActivity({int limit = 50}) async {
    final res = await _client.get(
      ApiEndpoints.dashboardActivity,
      queryParameters: {'limit': limit},
    );
    final list = res.data as List<dynamic>? ?? [];
    return list.map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EnrollmentTrendPoint>> getEnrollmentTrends() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final res = await _client.get(
      ApiEndpoints.enrollmentTrends,
      queryParameters: {
        'startDate': start.toUtc().toIso8601String(),
        'endDate': now.toUtc().toIso8601String(),
        'interval': 'day',
      },
    );
    final list = res.data as List<dynamic>? ?? [];
    return list
        .map((e) => EnrollmentTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryStat>> getCategoryStats() async {
    final res = await _client.get(ApiEndpoints.analyticsCategories);
    final list = res.data as List<dynamic>? ?? [];
    return list
        .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopInstructor>> getTopInstructors() async {
    final res = await _client.get(ApiEndpoints.topInstructors);
    final list = res.data as List<dynamic>? ?? [];
    return list
        .map((e) => TopInstructor.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
