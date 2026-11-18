import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/pg_switcher_title.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/pg_switcher_sheet.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePg = ref.watch(activePgProvider);
    final pgTitle = activePg?.name ?? AppConfig.appName;

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        titleWidget: PgSwitcherTitle(
          pgName: pgTitle,
          onTap: () => PgSwitcherSheet.show(context),
        ),
      ),
      body: const SizedBox.expand(),
    );
  }
}
