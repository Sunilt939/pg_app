import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';

class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        title: l10n.gateTitle(AppConfig.appName),
      ),
      body: const SizedBox.expand(),
    );
  }
}

