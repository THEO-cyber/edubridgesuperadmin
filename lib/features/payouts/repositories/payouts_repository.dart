import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/payout_models.dart';

final payoutsRepositoryProvider = Provider<PayoutsRepository>((ref) {
  return PayoutsRepository(ref.read(apiClientProvider));
});

class PayoutsRepository {
  PayoutsRepository(this._client);
  final ApiClient _client;

  Future<List<Payout>> getAllPayouts({int page = 1}) async {
    final res = await _client.get(
      ApiEndpoints.allPayouts,
      queryParameters: {'page': page},
    );
    final data = res.data;
    final list = (data is List ? data : data['payouts'] ?? data['data'] ?? []) as List<dynamic>;
    return list.map((e) => Payout.fromJson(e as Map<String, dynamic>)).toList();
  }
}
