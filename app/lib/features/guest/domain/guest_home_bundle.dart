import 'package:flutter/foundation.dart';
import '../../owner/domain/charge_balance.dart';
import '../../owner/domain/guest_list_item.dart';
import '../../owner/domain/payment_feed_item.dart';

@immutable
class GuestHomeBundle {
  final GuestListItem? currentStay;
  final GuestListItem? latestPastStay;
  final List<GuestListItem> previousStays;
  final List<ChargeBalance> charges;
  final List<PaymentFeedItem> payments;

  const GuestHomeBundle({
    this.currentStay,
    this.latestPastStay,
    this.previousStays = const [],
    this.charges = const [],
    this.payments = const [],
  });

  GuestListItem? get latestStay => currentStay ?? latestPastStay;
}

