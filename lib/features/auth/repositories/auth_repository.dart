import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(authStorageProvider));
});

class AuthRepository {
  AuthRepository(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  Future<LoginResult> login(String email, String password) async {
    final res = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = res.data as Map<String, dynamic>;

    // 2FA pending — server returns { requires2FA: true, tempToken }
    if (data['requires2FA'] == true || data['requiresTwoFactor'] == true) {
      final tempToken = data['tempToken']?.toString() ?? '';
      return LoginResult.requires2FA(tempToken);
    }

    final token = data['accessToken']?.toString() ?? data['token']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString();
    final user = AuthUser.fromJson(data, token);

    await _storage.saveSession(
      token: token,
      refreshToken: refreshToken,
      role: user.role,
      userId: user.id,
      email: user.email,
      name: user.displayName,
    );
    return LoginResult.authenticated(user);
  }

  Future<AuthUser> verify2FA(String tempToken, String totpCode) async {
    final res = await _client.post(
      ApiEndpoints.verify2FA,
      data: {'tempToken': tempToken, 'totpCode': totpCode},
    );
    final data = res.data as Map<String, dynamic>;
    final token = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString();
    final user = AuthUser.fromJson(data, token);

    await _storage.saveSession(
      token: token,
      refreshToken: refreshToken,
      role: user.role,
      userId: user.id,
      email: user.email,
      name: user.displayName,
    );
    return user;
  }

  Future<AuthUser?> restoreSession() async {
    if (!await _storage.hasSession()) return null;

    try {
      final res = await _client.get(ApiEndpoints.me);
      final data = res.data as Map<String, dynamic>;
      final token = await _storage.getToken() ?? '';
      return AuthUser.fromJson(data, token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clear();
        return null;
      }
      // Network error — fall back to cached data
      final token = await _storage.getToken();
      final role = await _storage.getRole();
      final userId = await _storage.getUserId();
      final email = await _storage.getEmail();
      final name = await _storage.getName();
      if (token == null || userId == null) return null;
      final parts = (name ?? '').split(' ');
      return AuthUser(
        id: userId,
        email: email ?? '',
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        role: role ?? 'ADMIN',
        token: token,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } on DioException {
      // ignore — always clear local session
    }
    await _storage.clear();
  }
}
