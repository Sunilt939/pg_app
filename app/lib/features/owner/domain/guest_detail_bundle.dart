import 'package:flutter/foundation.dart';

import 'charge_balance.dart';
import 'emergency_contact.dart';
import 'guest_list_item.dart';
import 'payment_feed_item.dart';

@immutable
class GuestDetailBundle {
  final GuestListItem guest;
  final List<ChargeBalance> charges;
  final List<PaymentFeedItem> payments;
  final EmergencyContact? emergencyContact;
  final int documentsCount;

  const GuestDetailBundle({
    required this.guest,
    this.charges = const [],
    this.payments = const [],
    this.emergencyContact,
    this.documentsCount = 0,
  });
}

