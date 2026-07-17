import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/category_models.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.read(apiClientProvider));
});

class CategoriesRepository {
  CategoriesRepository(this._client);
  final ApiClient _client;

  Future<List<Category>> getAll() async {
    final res = await _client.get(ApiEndpoints.categories);
    final data = res.data;
    final list = (data is List ? data : data['categories'] ?? data['data'] ?? []) as List<dynamic>;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> create({
    required String name,
    String? description,
    String? parentId,
    String? icon,
    bool? isActive,
  }) async {
    final res = await _client.post(ApiEndpoints.categories, data: {
      'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      if (icon != null && icon.isNotEmpty) 'icon': icon,
      if (isActive != null) 'isActive': isActive,
    });
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> update(
    String id, {
    String? name,
    String? description,
    String? icon,
    bool? isActive,
  }) async {
    final res = await _client.put(ApiEndpoints.category(id), data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      // An empty string clears the icon, so send it rather than skip it.
      if (icon != null) 'icon': icon,
      if (isActive != null) 'isActive': isActive,
    });
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _client.delete(ApiEndpoints.category(id));
}
