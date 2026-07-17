import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payout_models.dart';
import '../repositories/payouts_repository.dart';

final payoutsProvider = FutureProvider.autoDispose<List<Payout>>((ref) async {
  return ref.read(payoutsRepositoryProvider).getAllPayouts();
});
