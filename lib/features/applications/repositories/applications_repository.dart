import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/application_models.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  return ApplicationsRepository(ref.read(apiClientProvider));
});

class ApplicationsRepository {
  ApplicationsRepository(this._client);
  final ApiClient _client;

  Future<List<InstructorApplication>> getApplications({
    String? status,
    int page = 1,
  }) async {
    final res = await _client.get(
      ApiEndpoints.instructorApplications,
      queryParameters: {
        'page': page,
        if (status != null) 'status': status,
      },
    );
    final data = res.data;
    final list = (data is List ? data : data['applications'] ?? data['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => InstructorApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApplicationStats> getStats() async {
    final res = await _client.get(ApiEndpoints.applicationStats);
    return ApplicationStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> review(String id,
      {required String decision, String? rejectionReason}) =>
      _client.patch(ApiEndpoints.reviewApplication(id), data: {
        'decision': decision,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });
}
