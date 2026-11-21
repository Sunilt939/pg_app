import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/payment_account.dart';
import '../providers/owner_provider.dart';

class OwnerAccountsScreen extends ConsumerWidget {
  const OwnerAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(paymentAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        title: l10n.accountsTitle,
        leading: IconButton(
          icon: const Icon(AppIcons.back, size: 24, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.plus, size: 24, color: AppColors.ink),
            onPressed: () => context.push(RoutePaths.ownerAccountsNew),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpace.x12),
          child: SkeletonList(),
        ),
        error: (error, _) => Center(
          child: ErrorState(
            title: l10n.errorGeneric,
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(paymentAccountsProvider),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: EmptyState(
                icon: AppIcons.bank,
                title: l10n.accountsEmptyTitle,
                body: l10n.accountsEmptyBody,
                actionLabel: l10n.accountsEmptyAction,
                onAction: () => context.push(RoutePaths.ownerAccountsNew),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.petrol,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(paymentAccountsProvider);
              await ref.read(paymentAccountsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.only(
                top: AppSpace.x12,
                bottom: AppSpace.x32,
              ),
              children: [
                LedgerSheet(
                  children: [
                    for (int i = 0; i < accounts.length; i++)
                      _buildAccountRow(
                        context,
                        accounts[i],
                        l10n,
                        showDivider: i < accounts.length - 1,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    PaymentAccount account,
    AppLocalizations l10n, {
    required bool showDivider,
  }) {
    final isUpi = account.kind == 'upi';
    final subtitle = isUpi
        ? account.upiVpa
        : (account.accountLast4 != null && account.accountLast4!.isNotEmpty
            ? l10n.accountBankEnding(
                account.bankName ?? '',
                account.accountLast4!,
              )
            : account.bankName);

    Widget? trailing;
    if (account.isDefault || !account.isActive) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (account.isDefault)
            StatusChip.due(label: l10n.accountDefault),
          if (!account.isActive) ...[
            if (account.isDefault) const SizedBox(width: AppSpace.x8),
            StatusChip.due(label: l10n.accountOff),
          ],
        ],
      );
    }

    return LedgerRow(
      leading: RoomTile(
        icon: isUpi ? AppIcons.upi : AppIcons.bank,
      ),
      leadingGap: AppSpace.x12,
      title: account.nickname,
      subtitle: subtitle,
      trailing: trailing,
      showDivider: showDivider,
      onTap: () {
        context.push('/owner/accounts/${account.id}');
      },
    );
  }
}

