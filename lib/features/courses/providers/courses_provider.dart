import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_models.dart';
import '../repositories/courses_repository.dart';

final coursesFilterProvider =
    StateProvider<CoursesFilter>((ref) => const CoursesFilter());

final coursesProvider =
    FutureProvider.autoDispose<List<AdminCourse>>((ref) async {
  final filter = ref.watch(coursesFilterProvider);
  return ref.read(coursesRepositoryProvider).getCourses(filter);
});

class CoursesNotifier extends StateNotifier<AsyncValue<void>> {
  CoursesNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final CoursesRepository _repo;
  final Ref _ref;

  void _invalidate() => _ref.invalidate(coursesProvider);

  Future<bool> approve(String id) => _run(() => _repo.approve(id));

  Future<bool> reject(String id, String reason) =>
      _run(() => _repo.reject(id, reason));

  Future<bool> suspend(String id, String reason) =>
      _run(() => _repo.suspend(id, reason));

  Future<bool> _run(Future<void> Function() fn) async {
    state = const AsyncLoading();
    try {
      await fn();
      _invalidate();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final coursesActionProvider =
    StateNotifierProvider<CoursesNotifier, AsyncValue<void>>((ref) {
  return CoursesNotifier(ref.read(coursesRepositoryProvider), ref);
});

final pendingCoursesProvider =
    FutureProvider.autoDispose<List<AdminCourse>>((ref) async {
  return ref.read(coursesRepositoryProvider).getPendingCourses();
});

final courseReviewProvider =
    FutureProvider.autoDispose.family<CourseReviewDetail, String>((ref, id) async {
  return ref.read(coursesRepositoryProvider).getCourseReview(id);
});
