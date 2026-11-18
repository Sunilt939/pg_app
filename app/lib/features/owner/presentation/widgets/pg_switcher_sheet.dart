import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/pg_switcher_item.dart';
import '../providers/owner_provider.dart';

class PgSwitcherSheet extends ConsumerWidget {
  const PgSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      builder: (context) => const PgSwitcherSheet(),
    );
  }

  String _getRoleLabel(String role, AppLocalizations l10n) {
    switch (role.toLowerCase()) {
      case 'owner':
        return l10n.roleOwner;
      case 'manager':
        return l10n.roleManager;
      case 'caretaker':
        return l10n.roleCaretaker;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPgId = ref.watch(selectedPgIdProvider).valueOrNull;
    final pgsAsync = ref.watch(ownerPgsProvider);

    return AppBottomSheet(
      title: l10n.switcherTitle,
      padding: EdgeInsets.zero,
      child: pgsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpace.x16),
          child: SkeletonList(itemCount: 3),
        ),
        error: (_, __) => _buildList(context, ref, l10n, [], selectedPgId),
        data: (pgs) => _buildList(context, ref, l10n, pgs, selectedPgId),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<PgSwitcherItem> pgs,
    String? selectedPgId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pgs.length; i++) ...[
          _buildPgRow(context, ref, l10n, pgs[i], selectedPgId),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.hairline,
            indent: AppSpace.x16,
          ),
        ],
        _buildAddRow(context, l10n),
      ],
    );
  }

  Widget _buildPgRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PgSwitcherItem item,
    String? selectedPgId,
  ) {
    final isSelected = item.pgId == selectedPgId;
    final location = item.location;
    final roleLabel = _getRoleLabel(item.role, l10n);
    final subtitle = location.isNotEmpty ? '$location · $roleLabel' : roleLabel;

    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        if (item.pgId != selectedPgId) {
          await ref.read(selectedPgIdProvider.notifier).setPgId(item.pgId);
        }
      },
      splashColor: AppColors.transparent,
      highlightColor: AppColors.petrolTint,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppText.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpace.x12),
              const Icon(
                AppIcons.check,
                size: 20,
                color: AppColors.petrol,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddRow(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.push(RoutePaths.ownerPgNew);
      },
      splashColor: AppColors.transparent,
      highlightColor: AppColors.petrolTint,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x12,
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.plus,
              size: 20,
              color: AppColors.petrol,
            ),
            const SizedBox(width: AppSpace.x12),
            Text(
              l10n.switcherAdd,
              style: AppText.bodyMedium.copyWith(color: AppColors.petrol),
            ),
          ],
        ),
      ),
    );
  }
}

