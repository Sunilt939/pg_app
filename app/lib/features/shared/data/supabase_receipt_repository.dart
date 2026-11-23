import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/receipt_detail.dart';
import '../domain/receipt_repository.dart';

class SupabaseReceiptRepository implements ReceiptRepository {
  final SupabaseClient _client;

  SupabaseReceiptRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<ReceiptDetail?> getReceiptDetail(String paymentId) async {
    final response = await _client
        .from('v_receipt_detail')
        .select()
        .eq('payment_id', paymentId)
        .maybeSingle();

    if (response == null) return null;
    return ReceiptDetail.fromJson(response);
  }
}

