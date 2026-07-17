import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/user_models.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.read(apiClientProvider));
});

class UsersRepository {
  UsersRepository(this._client);
  final ApiClient _client;

  Future<UsersPage> getUsers(UsersFilter filter) async {
    final res = await _client.get(
      ApiEndpoints.users,
      queryParameters: filter.toQuery(),
    );
    final data = res.data as Map<String, dynamic>;
    final list = (data['users'] ?? data['data'] ?? data) as List<dynamic>? ?? [];
    final total = (data['total'] ?? data['count'] ?? list.length) as int? ?? list.length;
    return UsersPage(
      users: list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
      page: filter.page,
    );
  }

  Future<AdminUser> getUser(String id) async {
    final res = await _client.get(ApiEndpoints.user(id));
    return AdminUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUser> createUser({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String role,
    required String password,
  }) async {
    final res = await _client.post(ApiEndpoints.users, data: {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'password': password,
    });
    return AdminUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUser> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _client.put(ApiEndpoints.user(id), data: data);
    return AdminUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deactivateUser(String id) =>
      _client.put(ApiEndpoints.deactivateUser(id));

  Future<void> activateUser(String id) =>
      _client.put(ApiEndpoints.activateUser(id));

  Future<void> deleteUser(String id) =>
      _client.delete(ApiEndpoints.user(id));

  Future<void> changeRole(String id, String role) =>
      _client.put(ApiEndpoints.userRole(id), data: {'role': role});
}
