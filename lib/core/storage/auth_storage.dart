import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

/// Session storage for the super-admin console.
///
/// The admin holds the most powerful credentials in the system, so the JWTs
/// (access + refresh) live in the OS secure store (Keychain / Keystore /
/// Windows Credential Manager via flutter_secure_storage). Only non-sensitive
/// display fields (role, id, email, name) are kept in SharedPreferences.
class AuthStorage {
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
    required String email,
    required String name,
    String? refreshToken,
  }) async {
    await _secure.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _secure.write(key: _refreshTokenKey, value: refreshToken);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secure.write(key: _tokenKey, value: accessToken);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getToken() => _secure.read(key: _tokenKey);

  Future<String?> getRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _refreshTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
