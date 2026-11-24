import 'package:flutter/foundation.dart';
import 'guest_list_item.dart';
import 'payment_feed_item.dart';
import 'pg_monthly_summary.dart';
import 'pg_overview.dart';
import 'pg_setup_status.dart';

@immutable
class OwnerHomeBundle {
  final PgSetupStatus setupStatus;
  final PgOverview? overview;
  final PgMonthlySummary? monthlySummary;
  final List<PaymentFeedItem> pendingPayments;
  final List<GuestListItem> overdueGuests;
  final List<GuestListItem> openGuests;

  const OwnerHomeBundle({
    required this.setupStatus,
    this.overview,
    this.monthlySummary,
    this.pendingPayments = const [],
    this.overdueGuests = const [],
    this.openGuests = const [],
  });
}

