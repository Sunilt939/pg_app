import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_receipt_repository.dart';
import '../../domain/receipt_detail.dart';
import '../../domain/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return SupabaseReceiptRepository();
});

final receiptDetailProvider =
    FutureProvider.autoDispose.family<ReceiptDetail?, String>((ref, paymentId) async {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.getReceiptDetail(paymentId);
});

