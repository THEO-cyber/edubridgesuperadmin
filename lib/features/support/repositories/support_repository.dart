import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(apiClientProvider));
});

class SupportRepository {
  SupportRepository(this._client);
  final ApiClient _client;

  Future<List<SupportConversation>> getConversations() async {
    final res = await _client.get(ApiEndpoints.supportConversations);
    final data = res.data;
    final list = (data is List ? data : data['conversations'] ?? data['items'] ?? [])
        as List<dynamic>;
    return list
        .map((e) => SupportConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupportMessage>> getMessages(String roomId) async {
    final res = await _client.get(ApiEndpoints.supportMessages(roomId));
    final data = res.data;
    final list = (data is List ? data : data['messages'] ?? data['items'] ?? [])
        as List<dynamic>;
    return list
        .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> reply(String roomId, String content) =>
      _client.post(ApiEndpoints.supportReply(roomId), data: {'content': content});
}
