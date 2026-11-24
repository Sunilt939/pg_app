import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/pg_switcher_title.dart';
import '../../../../core/widgets/room_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/underline_tabs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/owner_repository.dart';
import '../../../shared/presentation/widgets/notification_bell_button.dart';
import '../providers/owner_provider.dart';
import '../widgets/confirm_payment_sheet.dart';
import '../widgets/pg_switcher_sheet.dart';
import '../widgets/reject_payment_sheet.dart';

class OwnerPaymentsScreen extends ConsumerStatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  ConsumerState<OwnerPaymentsScreen> createState() =>
      _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends ConsumerState<OwnerPaymentsScreen> {
  int _selectedTabIndex = 0;

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return DateFormat.formatDate(parsed);
  }

  String _formatDayHeader(String rawDate, AppLocalizations l10n) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(parsed.year, parsed.month, parsed.day);

    if (target == today) {
      return l10n.dayToday;
    } else if (target == yesterday) {
      return l10n.dayYesterday;
    } else if (parsed.year == now.year) {
      return DateFormat.formatShortDate(parsed);
    } else {
      return DateFormat.formatDate(parsed);
    }
  }

  IconData _paymentMethodIcon(String methodCode) {
    switch (methodCode.toLowerCase()) {
      case 'upi':
        return AppIcons.upi;
      case 'bank':
        return AppIcons.bank;
      case 'cash':
      case 'cheque':
      default:
        return AppIcons.cash;
    }
  }

  void _refresh() {
    ref.invalidate(pgPaymentsProvider);
    ref.invalidate(pgOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final pgTitle = activePg?.name ?? AppConfig.appName;
    final overviewAsync = ref.watch(pgOverviewProvider);
    final pendingCount = overviewAsync.valueOrNull?.pendingPaymentCount ?? 0;
    final paymentsAsync = ref.watch(pgPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        titleWidget: PgSwitcherTitle(
          pgName: pgTitle,
          onTap: () => PgSwitcherSheet.show(context),
        ),
        actions: const [
          NotificationBellButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnderlineTabs(
            tabs: [
              UnderlineTabItem(
                label: l10n.tabWaiting,
                count: pendingCount > 0 ? pendingCount : null,
              ),
              UnderlineTabItem(
                label: l10n.tabRecent,
              ),
            ],
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
          Expanded(
            child: paymentsAsync.when(
              loading: () => _buildLoadingState(),
              error: (err, stack) => ErrorState(
                title: l10n.errorGeneric,
                message: l10n.errorNetwork,
                onRetry: _refresh,
              ),
              data: (payments) => RefreshIndicator(
                color: AppColors.petrol,
                onRefresh: () async => _refresh(),
                child: _selectedTabIndex == 0
                    ? _buildWaitingTab(context, l10n, payments)
                    : _buildRecentTab(context, l10n, payments),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12),
      children: const [
        SkeletonList(itemCount: 4),
      ],
    );
  }

  Widget _buildWaitingTab(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentFeedItem> payments,
  ) {
    final pending = payments.where((p) => p.status == 'pending').toList()
      ..sort((a, b) {
        final dateComp = a.paidOn.compareTo(b.paidOn);
        if (dateComp != 0) return dateComp;
        return (a.createdAt ?? '').compareTo(b.createdAt ?? '');
      });

    if (pending.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyState(
            icon: AppIcons.clock,
            title: l10n.waitingEmptyTitle,
            body: l10n.waitingEmptyBody,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12, bottom: AppSpace.x32),
      children: [
        LedgerSheet(
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
          children: [
            for (int i = 0; i < pending.length; i++)
              _buildWaitingPaymentRow(
                context,
                l10n,
                pending[i],
                i < pending.length - 1,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaitingPaymentRow(
    BuildContext context,
    AppLocalizations l10n,
    PaymentFeedItem payment,
    bool showDivider,
  ) {
    final title = (payment.fullName != null &&
            payment.fullName!.trim().isNotEmpty)
        ? payment.fullName!.trim()
        : (payment.phone ?? '');

    return LedgerRow(
      leading: RoomTile(label: payment.roomNumber),
      title: title,
      subtitle: l10n.rowReported(
        MoneyFormat.format(payment.amountPaise),
        payment.methodLabel,
        _formatDate(payment.paidOn),
      ),
      paise: payment.amountPaise,
      statusKind: StatusChipKind.pending,
      showDivider: showDivider,
      onTap: () async {
        await context.push('/owner/payments/${payment.paymentId}');
        _refresh();
      },
      inlineActions: [
        AppButton.text(
          label: l10n.actionReject,
          textColor: AppColors.overdueFg,
          onPressed: () async {
            final res = await RejectPaymentSheet.show(
              context,
              payment: payment,
            );
            if (res == true) {
              _refresh();
            }
          },
        ),
        AppButton.text(
          label: l10n.actionConfirm,
          textColor: AppColors.petrol,
          onPressed: () async {
            final res = await ConfirmPaymentSheet.show(
              context,
              payment: payment,
            );
            if (res == true) {
              _refresh();
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecentTab(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentFeedItem> payments,
  ) {
    final recent = payments
        .where((p) =>
            p.status == 'confirmed' ||
            p.status == 'reversed' ||
            p.status == 'rejected')
        .take(50)
        .toList()
      ..sort((a, b) {
        final dateComp = b.paidOn.compareTo(a.paidOn);
        if (dateComp != 0) return dateComp;
        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      });

    final showCollectionsLink = AppFlags.isPageApproved('O10');

    if (recent.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (showCollectionsLink) _buildCollectionsLinkSheet(context, l10n),
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyState(
            icon: AppIcons.payments,
            title: l10n.paymentsEmptyTitle,
            body: l10n.paymentsEmptyBody,
          ),
        ],
      );
    }

    final Map<String, List<PaymentFeedItem>> grouped = {};
    for (final p in recent) {
      grouped.putIfAbsent(p.paidOn, () => []).add(p);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x12, bottom: AppSpace.x32),
      children: [
        if (showCollectionsLink) _buildCollectionsLinkSheet(context, l10n),
        for (final entry in grouped.entries) ...[
          SectionHeader(
            title: _formatDayHeader(entry.key, l10n),
          ),
          LedgerSheet(
            margin: const EdgeInsets.only(
              left: AppSpace.x16,
              right: AppSpace.x16,
              bottom: AppSpace.x12,
            ),
            children: [
              for (int i = 0; i < entry.value.length; i++)
                _buildRecentPaymentRow(
                  context,
                  l10n,
                  entry.value[i],
                  i < entry.value.length - 1,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCollectionsLinkSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return LedgerSheet(
      margin: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        bottom: AppSpace.x12,
      ),
      children: [
        LedgerRow(
          title: l10n.collectionsLink,
          trailing: const Icon(
            AppIcons.chevronRight,
            size: 20,
            color: AppColors.muted,
          ),
          showDivider: false,
          onTap: () => context.push('/owner/collections'),
        ),
      ],
    );
  }

  Widget _buildRecentPaymentRow(
    BuildContext context,
    AppLocalizations l10n,
    PaymentFeedItem payment,
    bool showDivider,
  ) {
    final title = (payment.fullName != null &&
            payment.fullName!.trim().isNotEmpty)
        ? payment.fullName!.trim()
        : (payment.phone ?? '');

    final parts = <String>[payment.methodLabel];
    if (payment.payerAppLabel != null &&
        payment.payerAppLabel!.trim().isNotEmpty) {
      parts.add(payment.payerAppLabel!.trim());
    }
    if (payment.roomNumber != null && payment.roomNumber!.trim().isNotEmpty) {
      parts.add('Room ${payment.roomNumber!.trim()}');
    }
    final subtitle = parts.join(', ');

    StatusChipKind? chipKind;
    String? chipLabel;
    if (payment.status == 'reversed') {
      chipKind = StatusChipKind.overdue;
      chipLabel = l10n.statusReversed;
    } else if (payment.status == 'rejected') {
      chipKind = StatusChipKind.overdue;
      chipLabel = l10n.statusRejected;
    }

    return LedgerRow(
      leading: RoomTile(icon: _paymentMethodIcon(payment.methodCode)),
      title: title,
      subtitle: subtitle,
      paise: payment.amountPaise,
      statusKind: chipKind,
      statusLabel: chipLabel,
      showDivider: showDivider,
      onTap: () async {
        await context.push('/owner/payments/${payment.paymentId}');
        _refresh();
      },
    );
  }
}
