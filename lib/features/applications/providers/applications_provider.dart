import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_models.dart';
import '../repositories/applications_repository.dart';

final applicationsStatusFilterProvider = StateProvider<String?>((ref) => null);

final applicationsProvider =
    FutureProvider.autoDispose<List<InstructorApplication>>((ref) async {
  final status = ref.watch(applicationsStatusFilterProvider);
  return ref
      .read(applicationsRepositoryProvider)
      .getApplications(status: status);
});

final applicationStatsProvider =
    FutureProvider.autoDispose<ApplicationStats>((ref) async {
  return ref.read(applicationsRepositoryProvider).getStats();
});

class ApplicationsNotifier extends StateNotifier<AsyncValue<void>> {
  ApplicationsNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final ApplicationsRepository _repo;
  final Ref _ref;

  void _invalidate() {
    _ref.invalidate(applicationsProvider);
    _ref.invalidate(applicationStatsProvider);
  }

  Future<bool> approve(String id) =>
      _run(() => _repo.review(id, decision: 'approved'));

  Future<bool> reject(String id, String reason) =>
      _run(() => _repo.review(id,
          decision: 'rejected', rejectionReason: reason));

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

final applicationsActionProvider =
    StateNotifierProvider<ApplicationsNotifier, AsyncValue<void>>((ref) {
  return ApplicationsNotifier(ref.read(applicationsRepositoryProvider), ref);
});
