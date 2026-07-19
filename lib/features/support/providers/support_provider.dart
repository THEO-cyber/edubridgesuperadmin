import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_models.dart';
import '../repositories/support_repository.dart';

/// The conversation currently open in the reading pane (null = none selected).
final selectedSupportRoomProvider = StateProvider<String?>((ref) => null);

final supportConversationsProvider =
    FutureProvider.autoDispose<List<SupportConversation>>((ref) async {
  return ref.read(supportRepositoryProvider).getConversations();
});

final supportMessagesProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, roomId) async {
  return ref.read(supportRepositoryProvider).getMessages(roomId);
});

class SupportReplyNotifier extends StateNotifier<AsyncValue<void>> {
  SupportReplyNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final SupportRepository _repo;
  final Ref _ref;

  Future<bool> send(String roomId, String content) async {
    state = const AsyncLoading();
    try {
      await _repo.reply(roomId, content);
      _ref.invalidate(supportMessagesProvider(roomId));
      _ref.invalidate(supportConversationsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final supportReplyProvider =
    StateNotifierProvider<SupportReplyNotifier, AsyncValue<void>>((ref) {
  return SupportReplyNotifier(ref.read(supportRepositoryProvider), ref);
});
