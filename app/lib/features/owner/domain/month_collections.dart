import 'package:flutter/foundation.dart';

@immutable
class AccountCollection {
  final String? accountId;
  final String? accountNickname;
  final String methodCode;
  final String methodLabel;
  final int paymentCount;
  final int totalPaise;

  const AccountCollection({
    this.accountId,
    this.accountNickname,
    required this.methodCode,
    this.methodLabel = '',
    this.paymentCount = 0,
    this.totalPaise = 0,
  });

  factory AccountCollection.fromJson(Map<String, dynamic> json) {
    final method = (json['method_code'] as String? ?? 'cash').toLowerCase();
    String defaultLabel;
    switch (method) {
      case 'upi':
        defaultLabel = 'UPI';
        break;
      case 'bank':
        defaultLabel = 'Bank transfer';
        break;
      case 'cash':
      default:
        defaultLabel = 'Cash';
        break;
    }

    return AccountCollection(
      accountId: json['received_account_id'] as String?,
      accountNickname: json['account_nickname'] as String?,
      methodCode: method,
      methodLabel: defaultLabel,
      paymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
      totalPaise: (json['total_paise'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class MonthCollections {
  final String pgId;
  final String month;
  final int totalPaise;
  final int paymentCount;
  final List<AccountCollection> byAccount;

  const MonthCollections({
    required this.pgId,
    required this.month,
    this.totalPaise = 0,
    this.paymentCount = 0,
    this.byAccount = const [],
  });

  factory MonthCollections.empty(String pgId, String month) {
    return MonthCollections(
      pgId: pgId,
      month: month,
      totalPaise: 0,
      paymentCount: 0,
      byAccount: const [],
    );
  }
}

