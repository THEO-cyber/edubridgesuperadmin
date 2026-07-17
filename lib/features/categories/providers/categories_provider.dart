import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_models.dart';
import '../repositories/categories_repository.dart';

final categoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.read(categoriesRepositoryProvider).getAll();
});

class CategoriesNotifier extends StateNotifier<AsyncValue<void>> {
  CategoriesNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final CategoriesRepository _repo;
  final Ref _ref;

  void _invalidate() => _ref.invalidate(categoriesProvider);

  Future<bool> create({
    required String name,
    String? description,
    String? icon,
    bool? isActive,
  }) =>
      _run(() => _repo.create(
            name: name,
            description: description,
            icon: icon,
            isActive: isActive,
          ));

  Future<bool> update(
    String id, {
    String? name,
    String? description,
    String? icon,
    bool? isActive,
  }) =>
      _run(() => _repo.update(
            id,
            name: name,
            description: description,
            icon: icon,
            isActive: isActive,
          ));

  Future<bool> delete(String id) => _run(() => _repo.delete(id));

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

final categoriesActionProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<void>>((ref) {
  return CategoriesNotifier(ref.read(categoriesRepositoryProvider), ref);
});
