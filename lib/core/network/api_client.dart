import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/auth_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(authStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // The backend wraps every response in { success, data, timestamp }.
        // Unwrap it so repositories can read res.data['x'] directly.
        response.data = _unwrapEnvelope(response.data);
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRetry(error.requestOptions)) {
          try {
            await _refresh();
            final retry = await _retry(error.requestOptions);
            handler.resolve(retry);
            return;
          } catch (_) {
            await _storage.clear();
            if (_onSessionExpired != null) _onSessionExpired!();
          }
        }
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final AuthStorage _storage;
  void Function()? _onSessionExpired;
  bool _refreshing = false;

  /// Returns the inner payload of the backend's { success, data, timestamp }
  /// envelope, or the value unchanged when there is no envelope.
  static dynamic _unwrapEnvelope(dynamic body) {
    if (body is Map &&
        body['data'] != null &&
        (body.containsKey('success') || body.containsKey('timestamp'))) {
      return body['data'];
    }
    return body;
  }

  void setSessionExpiredCallback(void Function() cb) {
    _onSessionExpired = cb;
  }

  bool _isRetry(RequestOptions options) =>
      options.extra['_retry'] == true;

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) throw Exception('No refresh token');
      final res = await Dio().post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}',
        data: {'refreshToken': refreshToken},
      );
      // This bare Dio bypasses the interceptor, so unwrap the envelope here too.
      final data = _unwrapEnvelope(res.data) as Map<String, dynamic>;
      final newAccess = data['accessToken']?.toString() ?? '';
      final newRefresh = data['refreshToken']?.toString() ?? refreshToken;
      await _storage.saveTokens(newAccess, newRefresh);
    } finally {
      _refreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final token = await _storage.getToken();
    final opts = Options(
      method: options.method,
      headers: {
        ...options.headers,
        'Authorization': 'Bearer $token',
      },
      extra: {...options.extra, '_retry': true},
    );
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: opts,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
