import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/auth_repository.dart';
import '../../owner/domain/charge_balance.dart';
import '../../owner/domain/guest_list_item.dart';
import '../../owner/domain/payment_feed_item.dart';
import '../domain/guest_home_bundle.dart';
import '../domain/guest_repository.dart';

class SupabaseGuestRepository implements GuestRepository {
  final SupabaseClient? _client;

  SupabaseGuestRepository([SupabaseClient? client])
      : _client = client ??
            (Supabase.instance.isInitialized ? Supabase.instance.client : null);

  @override
  Future<GuestHomeBundle> getGuestHomeData() async {
    final client = _client;
    if (client == null) throw const AuthNetworkException();

    final user = client.auth.currentUser;
    if (user == null) throw const AuthNetworkException();

    // Query all stays of the signed-in person
    final staysResp = await client
        .from('v_guest_list')
        .select()
        .order('join_date', ascending: false);

    final allStays = (staysResp as List)
        .map((e) => GuestListItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final currentStay = allStays
        .where((s) => s.stayStatus != 'vacated')
        .firstOrNull;

    final latestPastStay = allStays
        .where((s) => s.stayStatus == 'vacated')
        .firstOrNull;

    final targetStay = currentStay ?? latestPastStay;
    if (targetStay == null) {
      return const GuestHomeBundle();
    }

    final chargesResp = await client
        .from('v_charge_balances')
        .select()
        .eq('stay_id', targetStay.stayId)
        .order('due_date', ascending: false);

    final charges = (chargesResp as List)
        .map((e) => ChargeBalance.fromJson(e as Map<String, dynamic>))
        .toList();

    final paymentsResp = await client
        .from('v_payment_feed')
        .select()
        .eq('stay_id', targetStay.stayId)
        .order('paid_on', ascending: false);

    final payments = (paymentsResp as List)
        .map((e) => PaymentFeedItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return GuestHomeBundle(
      currentStay: currentStay,
      latestPastStay: latestPastStay,
      charges: charges,
      payments: payments,
    );
  }
}

