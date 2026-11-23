import 'receipt_detail.dart';

abstract class ReceiptRepository {
  Future<ReceiptDetail?> getReceiptDetail(String paymentId);
}

