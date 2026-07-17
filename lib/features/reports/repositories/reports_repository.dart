import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.read(apiClientProvider));
});

class ReportsRepository {
  ReportsRepository(this._client);
  final ApiClient _client;

  Future<List<ContentReport>> getReports({
    String? status,
    String? targetType,
    int page = 1,
  }) async {
    final res = await _client.get(
      ApiEndpoints.reports,
      queryParameters: {
        'page': page,
        if (status != null) 'status': status,
        if (targetType != null) 'targetType': targetType,
      },
    );
    final data = res.data;
    final list = (data is List ? data : data['reports'] ?? data['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => ContentReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReportStats> getStats() async {
    final res = await _client.get(ApiEndpoints.reportStats);
    return ReportStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> review(String id,
      {required String status, required String resolution}) =>
      _client.patch(ApiEndpoints.reviewReport(id), data: {
        'status': status,
        'resolution': resolution,
      });
}
