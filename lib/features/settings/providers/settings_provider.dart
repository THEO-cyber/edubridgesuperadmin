import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/setting_models.dart';
import '../repositories/settings_repository.dart';

final settingsProvider =
    FutureProvider.autoDispose<List<SystemSetting>>((ref) async {
  return ref.read(settingsRepositoryProvider).getAll();
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  SettingsNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final SettingsRepository _repo;
  final Ref _ref;

  void _invalidate() => _ref.invalidate(settingsProvider);

  Future<bool> create(SystemSetting s) => _run(() => _repo.create(s));

  Future<bool> update(String key, String value) =>
      _run(() => _repo.update(key, value));

  Future<bool> delete(String key) => _run(() => _repo.delete(key));

  Future<bool> bulkUpsert(List<SystemSetting> settings) =>
      _run(() => _repo.bulkUpsert(settings));

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

final settingsActionProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier(ref.read(settingsRepositoryProvider), ref);
});
