import 'package:flutter/foundation.dart';
import '../../owner/domain/charge_balance.dart';
import '../../owner/domain/guest_list_item.dart';
import '../../owner/domain/payment_feed_item.dart';

@immutable
class GuestStayBundle {
  final GuestListItem? stay;
  final List<ChargeBalance> charges;
  final List<PaymentFeedItem> payments;

  const GuestStayBundle({
    this.stay,
    this.charges = const [],
    this.payments = const [],
  });
}

