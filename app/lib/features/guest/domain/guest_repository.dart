import '../../owner/domain/guest_list_item.dart';
import '../../owner/domain/payment_account.dart';
import 'guest_home_bundle.dart';

abstract class GuestRepository {
  Future<GuestHomeBundle> getGuestHomeData();
  Future<GuestListItem?> getStay(String stayId);
  Future<List<PaymentAccount>> getActiveUpiAccounts(String pgId);
}

