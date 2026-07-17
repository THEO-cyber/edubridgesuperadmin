import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/setting_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(apiClientProvider));
});

class SettingsRepository {
  SettingsRepository(this._client);
  final ApiClient _client;

  Future<List<SystemSetting>> getAll() async {
    final res = await _client.get(ApiEndpoints.settings);
    final data = res.data;
    final list = (data is List ? data : data['settings'] ?? data['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => SystemSetting.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SystemSetting> create(SystemSetting setting) async {
    final res = await _client.post(ApiEndpoints.settings, data: {
      'key': setting.key,
      'value': setting.value,
      if (setting.description != null) 'description': setting.description,
      'isPublic': setting.isPublic,
    });
    return SystemSetting.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SystemSetting> update(String key, String value) async {
    final res = await _client.put(
      ApiEndpoints.setting(key),
      data: {'value': value},
    );
    return SystemSetting.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String key) =>
      _client.delete(ApiEndpoints.setting(key));

  Future<void> bulkUpsert(List<SystemSetting> settings) =>
      _client.patch(ApiEndpoints.settingsBulk, data: settings
          .map((s) => {'key': s.key, 'value': s.value})
          .toList());
}
