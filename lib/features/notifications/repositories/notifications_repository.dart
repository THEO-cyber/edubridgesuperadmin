import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_models.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(apiClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._client);
  final ApiClient _client;

  Future<void> broadcast({
    required String role,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    await _client.post(ApiEndpoints.notifyBroadcast, data: {
      'role': role,
      'title': title,
      'message': message,
      if (actionUrl != null && actionUrl.isNotEmpty) 'actionUrl': actionUrl,
    });
  }

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    await _client.post(ApiEndpoints.notifyUser(userId), data: {
      'title': title,
      'message': message,
      if (actionUrl != null && actionUrl.isNotEmpty) 'actionUrl': actionUrl,
    });
  }

  Future<void> notifyGroup({
    required List<String> userIds,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    await _client.post(ApiEndpoints.notifyUsers, data: {
      'userIds': userIds,
      'title': title,
      'message': message,
      if (actionUrl != null && actionUrl.isNotEmpty) 'actionUrl': actionUrl,
    });
  }

  Future<NotificationsPage> listNotifications({int page = 1, int limit = 20}) async {
    final res = await _client.get(
      ApiEndpoints.notificationsList,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data as Map<String, dynamic>;
    final list = (data['notifications'] as List<dynamic>? ?? []);
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    final total = (pagination['total'] as num?)?.toInt() ?? list.length;
    return NotificationsPage(
      notifications: list
          .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
    );
  }

  Future<AdminNotification> updateNotification(
    String id, {
    String? title,
    String? message,
    String? actionUrl,
  }) async {
    final res = await _client.patch(ApiEndpoints.notification(id), data: {
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (actionUrl != null) 'actionUrl': actionUrl,
    });
    return AdminNotification.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteNotification(String id) =>
      _client.delete(ApiEndpoints.notification(id));
}
