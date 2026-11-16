import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';

class ReceiptScreen extends StatelessWidget {
  final String? paymentId;

  const ReceiptScreen({super.key, this.paymentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.close(
        title: l10n.receiptTitle,
      ),
      body: const SizedBox.expand(),
    );
  }
}

