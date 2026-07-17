import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../repositories/users_repository.dart';

final usersFilterProvider = StateProvider<UsersFilter>((ref) => const UsersFilter());

final usersProvider = FutureProvider.autoDispose<UsersPage>((ref) async {
  final filter = ref.watch(usersFilterProvider);
  return ref.read(usersRepositoryProvider).getUsers(filter);
});

class UsersNotifier extends StateNotifier<AsyncValue<void>> {
  UsersNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final UsersRepository _repo;
  final Ref _ref;

  void _invalidate() => _ref.invalidate(usersProvider);

  Future<bool> deactivate(String id) => _run(() => _repo.deactivateUser(id));
  Future<bool> activate(String id) => _run(() => _repo.activateUser(id));
  Future<bool> delete(String id) => _run(() => _repo.deleteUser(id));

  Future<bool> changeRole(String id, String role) =>
      _run(() => _repo.changeRole(id, role));

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

final usersActionProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<void>>((ref) {
  return UsersNotifier(ref.read(usersRepositoryProvider), ref);
});
