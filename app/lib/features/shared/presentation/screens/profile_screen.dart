import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: canPop
          ? AppTopBar.back(title: l10n.profileTitle)
          : AppTopBar(title: l10n.profileTitle),
      body: const SizedBox.expand(),
    );
  }
}
