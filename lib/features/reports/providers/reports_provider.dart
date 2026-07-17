import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_models.dart';
import '../repositories/reports_repository.dart';

final reportsStatusFilterProvider = StateProvider<String?>((ref) => null);

final reportsProvider =
    FutureProvider.autoDispose<List<ContentReport>>((ref) async {
  final status = ref.watch(reportsStatusFilterProvider);
  return ref.read(reportsRepositoryProvider).getReports(status: status);
});

final reportStatsProvider =
    FutureProvider.autoDispose<ReportStats>((ref) async {
  return ref.read(reportsRepositoryProvider).getStats();
});

class ReportsNotifier extends StateNotifier<AsyncValue<void>> {
  ReportsNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final ReportsRepository _repo;
  final Ref _ref;

  void _invalidate() {
    _ref.invalidate(reportsProvider);
    _ref.invalidate(reportStatsProvider);
  }

  Future<bool> resolve(String id,
      {required String status, required String resolution}) =>
      _run(() => _repo.review(id, status: status, resolution: resolution));

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

final reportsActionProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<void>>((ref) {
  return ReportsNotifier(ref.read(reportsRepositoryProvider), ref);
});
