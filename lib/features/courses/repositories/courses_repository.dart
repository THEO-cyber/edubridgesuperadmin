import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/course_models.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository(ref.read(apiClientProvider));
});

class CoursesRepository {
  CoursesRepository(this._client);
  final ApiClient _client;

  Future<List<AdminCourse>> getCourses(CoursesFilter filter) async {
    final res = await _client.get(
      ApiEndpoints.courses,
      queryParameters: filter.toQuery(),
    );
    final data = res.data;
    final list = (data is List ? data : data['courses'] ?? data['data'] ?? []) as List<dynamic>;
    return list.map((e) => AdminCourse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminCourse>> getPendingCourses() async {
    final res = await _client.get(ApiEndpoints.pendingCourses);
    final data = res.data;
    final list = (data is List ? data : data['courses'] ?? data['data'] ?? []) as List<dynamic>;
    return list.map((e) => AdminCourse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CourseReviewDetail> getCourseReview(String id) async {
    final path = ApiEndpoints.courseReview(id);
    final res = await _client.get(path);
    return CourseReviewDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approve(String id) =>
      _client.put(ApiEndpoints.approveCourse(id));

  Future<void> reject(String id, String reason) =>
      _client.put(ApiEndpoints.rejectCourse(id), data: {'reason': reason});

  Future<void> suspend(String id, String reason) =>
      _client.put(ApiEndpoints.suspendCourse(id), data: {'reason': reason});
}
