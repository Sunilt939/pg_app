import '../../owner/domain/guest_list_item.dart';
import '../../owner/domain/payment_account.dart';
import '../../owner/domain/payment_method.dart';
import '../../owner/domain/upi_app.dart';
import 'guest_home_bundle.dart';
import 'guest_stay_bundle.dart';

abstract class GuestRepository {
  Future<GuestHomeBundle> getGuestHomeData();
  Future<GuestListItem?> getStay(String stayId);
  Future<GuestStayBundle> getStayDetails(String stayId);
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId);
  Future<List<PaymentAccount>> getActiveBankAccounts(String pgId);
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<List<UpiApp>> getUpiApps();
  Future<String> reportPayment({
    required String stayId,
    required int amountPaise,
    required String methodCode,
    DateTime? paidOn,
    String? accountId,
    String? payerAppCode,
    String? payerPhone,
    String? utr,
    String? note,
    String? screenshotFileId,
  });
}

