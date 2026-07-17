import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_models.dart';
import '../repositories/dashboard_repository.dart';

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.read(dashboardRepositoryProvider).getStats();
});

final activityProvider =
    FutureProvider.autoDispose<List<ActivityEvent>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getActivity();
});

final enrollmentTrendsProvider =
    FutureProvider.autoDispose<List<EnrollmentTrendPoint>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getEnrollmentTrends();
});

final categoryStatsProvider =
    FutureProvider.autoDispose<List<CategoryStat>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getCategoryStats();
});

final topInstructorsProvider =
    FutureProvider.autoDispose<List<TopInstructor>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getTopInstructors();
});
