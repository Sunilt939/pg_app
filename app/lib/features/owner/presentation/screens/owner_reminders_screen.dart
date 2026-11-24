import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/option_row.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/owner_repository.dart';
import '../providers/owner_provider.dart';

class OwnerRemindersScreen extends ConsumerStatefulWidget {
  const OwnerRemindersScreen({super.key});

  @override
  ConsumerState<OwnerRemindersScreen> createState() => _OwnerRemindersScreenState();
}

class _OwnerRemindersScreenState extends ConsumerState<OwnerRemindersScreen> {
  void _openSheet(BuildContext context, [ReminderRule? rule]) {
    final activePg = ref.read(activePgProvider);
    if (activePg == null) return;

    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => _ReminderRuleSheet(
        pgId: activePg.pgId,
        rule: rule,
        onSaved: () {
          ref.invalidate(reminderRulesProvider);
        },
      ),
    );
  }

  Future<void> _toggleRule(ReminderRule rule, bool newValue) async {
    final repo = ref.read(ownerRepositoryProvider);
    await repo.toggleReminderRule(id: rule.id, isActive: newValue);
    ref.invalidate(reminderRulesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rulesAsync = ref.watch(reminderRulesProvider);

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar.back(
        title: l10n.remindersTitle,
        actions: [
          IconButton(
            icon: const Icon(
              AppIcons.add,
              size: AppSize.icon,
              color: AppColors.ink,
            ),
            tooltip: l10n.remindersEmptyAction,
            onPressed: () => _openSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.petrol,
        onRefresh: () async => ref.refresh(reminderRulesProvider.future),
        child: rulesAsync.when(
          loading: _buildLoadingSkeleton,
          error: (err, _) => _buildError(l10n),
          data: (rules) => _buildContent(context, l10n, rules),
        ),
      ),
    );
  }

  Widget _buildNoticeBanner(AppLocalizations l10n) {
    if (AppFlags.remindersEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpace.x16,
        right: AppSpace.x16,
        top: AppSpace.x16,
        bottom: AppSpace.x12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pendingBg,
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.info,
            size: AppSize.iconSmall,
            color: AppColors.pendingFg,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(
              l10n.remindersSoon,
              style: AppText.secondary.copyWith(color: AppColors.pendingFg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<ReminderRule> rules,
  ) {
    if (rules.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildNoticeBanner(l10n),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: EmptyState(
              icon: AppIcons.bell,
              title: l10n.remindersEmptyTitle,
              body: l10n.remindersEmptyBody,
              actionLabel: l10n.remindersEmptyAction,
              onAction: () => _openSheet(context),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpace.x32),
      children: [
        _buildNoticeBanner(l10n),
        LedgerSheet(
          children: [
            for (int i = 0; i < rules.length; i++) ...[
              _buildRuleRow(l10n, rules[i], showDivider: i < rules.length - 1),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRuleRow(
    AppLocalizations l10n,
    ReminderRule rule, {
    required bool showDivider,
  }) {
    final title = _formatRuleTitle(l10n, rule.daysFromDue);
    final subtitle = _formatChannel(l10n, rule.channel);

    return LedgerRow(
      title: title,
      titleStyle: AppText.bodyMedium,
      subtitle: subtitle,
      showDivider: showDivider,
      onTap: () => _openSheet(context, rule),
      trailing: RuleSwitch(
        value: rule.isActive,
        onChanged: (val) => _toggleRule(rule, val),
      ),
    );
  }

  String _formatRuleTitle(AppLocalizations l10n, int days) {
    if (days < 0) {
      return l10n.remindBefore(days.abs());
    } else if (days == 0) {
      return l10n.remindOn;
    } else {
      return l10n.remindAfter(days);
    }
  }

  String _formatChannel(AppLocalizations l10n, String channel) {
    switch (channel) {
      case 'push':
        return l10n.channelPush;
      case 'sms':
        return l10n.channelSms;
      case 'whatsapp':
        return l10n.channelWhatsapp;
      default:
        return channel;
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpace.x16),
      children: const [
        LedgerSheet(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpace.x16),
              child: SkeletonBlock(height: 48),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.hairline),
            Padding(
              padding: EdgeInsets.all(AppSpace.x16),
              child: SkeletonBlock(height: 48),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: ErrorState(
            title: l10n.errorGeneric,
            message: l10n.errorNetwork,
            onRetry: () => ref.refresh(reminderRulesProvider),
          ),
        ),
      ],
    );
  }
}

class RuleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RuleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.petrol : AppColors.ground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.petrol : AppColors.outline,
            width: 1.5,
          ),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? AppColors.surface : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _ReminderRuleSheet extends ConsumerStatefulWidget {
  final String pgId;
  final ReminderRule? rule;
  final VoidCallback onSaved;

  const _ReminderRuleSheet({
    required this.pgId,
    this.rule,
    required this.onSaved,
  });

  @override
  ConsumerState<_ReminderRuleSheet> createState() => _ReminderRuleSheetState();
}

class _ReminderRuleSheetState extends ConsumerState<_ReminderRuleSheet> {
  late String _when;
  late TextEditingController _daysController;
  String? _daysError;
  String? _duplicateError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule != null) {
      if (rule.daysFromDue < 0) {
        _when = 'before';
        _daysController = TextEditingController(text: rule.daysFromDue.abs().toString());
      } else if (rule.daysFromDue == 0) {
        _when = 'on';
        _daysController = TextEditingController(text: '1');
      } else {
        _when = 'after';
        _daysController = TextEditingController(text: rule.daysFromDue.toString());
      }
    } else {
      _when = 'before';
      _daysController = TextEditingController(text: '3');
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    setState(() {
      _daysError = null;
      _duplicateError = null;
    });

    int daysFromDue = 0;
    if (_when != 'on') {
      final text = _daysController.text.trim();
      final parsed = int.tryParse(text);
      if (parsed == null) {
        setState(() => _daysError = 'Enter a valid number of days');
        return;
      }

      if (_when == 'before') {
        if (parsed < 1 || parsed > 30) {
          setState(() => _daysError = 'Must be between 1 and 30 days');
          return;
        }
        daysFromDue = -parsed;
      } else if (_when == 'after') {
        if (parsed < 1 || parsed > 60) {
          setState(() => _daysError = 'Must be between 1 and 60 days');
          return;
        }
        daysFromDue = parsed;
      }
    } else {
      daysFromDue = 0;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(ownerRepositoryProvider);
      await repo.saveReminderRule(
        id: widget.rule?.id,
        pgId: widget.pgId,
        daysFromDue: daysFromDue,
        channel: 'push',
      );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } on DuplicateReminderRuleException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _duplicateError = l10n.errReminderExists;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _duplicateError = l10n.errorGeneric;
        });
      }
    }
  }

  Future<void> _handleDelete(AppLocalizations l10n) async {
    final rule = widget.rule;
    if (rule == null) return;

    final confirmed = await ConfirmSheet.show(
      context: context,
      title: l10n.remindRemove,
      body: 'Are you sure you want to remove this reminder?',
      confirmLabel: l10n.remindRemove,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(ownerRepositoryProvider);
        await repo.deleteReminderRule(rule.id);
        widget.onSaved();
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.rule != null;

    return AppBottomSheet(
      title: isEditing ? l10n.remindersTitle : l10n.remindersEmptyAction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "When" OptionRow
          Text(l10n.remindWhen, style: AppText.label),
          const SizedBox(height: AppSpace.x8),
          OptionRow<String>(
            selectedValue: _when,
            onChanged: (val) {
              setState(() {
                _when = val;
                _duplicateError = null;
              });
            },
            options: [
              OptionRowItem(value: 'before', label: l10n.remindWhenBefore),
              OptionRowItem(value: 'on', label: l10n.remindWhenOn),
              OptionRowItem(value: 'after', label: l10n.remindWhenAfter),
            ],
          ),
          const SizedBox(height: AppSpace.x16),

          // "Days" number field (hidden for "on")
          if (_when != 'on') ...[
            AppTextField(
              label: l10n.remindDays,
              controller: _daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: _daysError,
              hint: _when == 'before' ? '1 to 30' : '1 to 60',
            ),
            const SizedBox(height: AppSpace.x16),
          ],

          // "How" OptionRow
          Text(l10n.remindHow, style: AppText.label),
          const SizedBox(height: AppSpace.x8),
          OptionRow<String>(
            selectedValue: 'push',
            options: [
              OptionRowItem(
                value: 'push',
                label: l10n.channelPush,
                isEnabled: true,
              ),
              OptionRowItem(
                value: 'sms',
                label: l10n.channelSms,
                isEnabled: false,
                subtitle: l10n.comingLater,
              ),
              OptionRowItem(
                value: 'whatsapp',
                label: l10n.channelWhatsapp,
                isEnabled: false,
                subtitle: l10n.comingLater,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x16),

          if (_duplicateError != null) ...[
            Text(
              _duplicateError!,
              style: AppText.secondary.copyWith(color: AppColors.overdueFg),
            ),
            const SizedBox(height: AppSpace.x16),
          ],

          // Save Button
          AppButton.primary(
            label: l10n.actionSave,
            expand: true,
            loading: _isLoading,
            onPressed: () => _handleSave(l10n),
          ),

          // Delete button in edit mode
          if (isEditing) ...[
            const SizedBox(height: AppSpace.x8),
            AppButton.text(
              label: l10n.remindRemove,
              expand: true,
              textColor: AppColors.overdueFg,
              onPressed: _isLoading ? null : () => _handleDelete(l10n),
            ),
          ],
        ],
      ),
    );
  }
}
