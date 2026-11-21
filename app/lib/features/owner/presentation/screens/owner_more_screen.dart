import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/ledger_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/pg_switcher_title.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/pg_switcher_sheet.dart';

class OwnerMoreScreen extends ConsumerWidget {
  const OwnerMoreScreen({super.key});

  Future<void> _handleSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await ConfirmSheet.show(
      context: context,
      title: l10n.signOutTitle(AppConfig.appName),
      body: l10n.signOutBody,
      confirmLabel: l10n.actionSignOut,
      cancelLabel: l10n.actionCancel,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.invalidate(authContextProvider);
      if (context.mounted) {
        context.go(RoutePaths.signIn);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePg = ref.watch(activePgProvider);
    final pgTitle = activePg?.name ?? AppConfig.appName;
    final authContext = ref.watch(authContextProvider).valueOrNull;
    final isGuest = authContext?.isGuest ?? false;

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppTopBar(
        titleWidget: PgSwitcherTitle(
          pgName: pgTitle,
          onTap: () => PgSwitcherSheet.show(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.x32),
        children: [
          // Section 1: Your PG
          SectionHeader(title: l10n.moreYourPg),
          LedgerSheet(
            children: [
              LedgerRow(
                leading: const Icon(
                  AppIcons.room,
                  size: 24,
                  color: AppColors.ink,
                ),
                leadingGap: AppSpace.x16,
                title: l10n.moreRooms,
                titleStyle: AppText.body,
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                minHeight: 56,
                showDivider: false,
                onTap: () {
                  context.push(RoutePaths.ownerRooms);
                },
              ),
            ],
          ),

          // Section 2: Account
          SectionHeader(title: l10n.moreAccount),
          LedgerSheet(
            children: [
              LedgerRow(
                leading: const Icon(
                  AppIcons.profile,
                  size: 24,
                  color: AppColors.ink,
                ),
                leadingGap: AppSpace.x16,
                title: l10n.moreProfile,
                titleStyle: AppText.body,
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                minHeight: 56,
                showDivider: true,
                onTap: () {
                  context.push(RoutePaths.profile);
                },
              ),
              if (isGuest)
                LedgerRow(
                  leading: const Icon(
                    AppIcons.user,
                    size: 24,
                    color: AppColors.ink,
                  ),
                  leadingGap: AppSpace.x16,
                  title: l10n.moreSwitchGuest,
                  titleStyle: AppText.body,
                  trailing: const Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  minHeight: 56,
                  showDivider: true,
                  onTap: () async {
                    await ref.read(authRepositoryProvider).setLastView('guest');
                    if (context.mounted) {
                      context.go(RoutePaths.guestHome);
                    }
                  },
                ),
              LedgerRow(
                leading: const Icon(
                  AppIcons.add,
                  size: 24,
                  color: AppColors.ink,
                ),
                leadingGap: AppSpace.x16,
                title: l10n.moreAddPg,
                titleStyle: AppText.body,
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                minHeight: 56,
                showDivider: false,
                onTap: () {
                  context.push(RoutePaths.ownerPgNew);
                },
              ),
            ],
          ),

          // Section 3: About (if termsUrl or privacyUrl is configured)
          if (AppConfig.termsUrl.isNotEmpty || AppConfig.privacyUrl.isNotEmpty) ...[
            SectionHeader(title: l10n.moreAbout),
            LedgerSheet(
              children: [
                if (AppConfig.termsUrl.isNotEmpty)
                  LedgerRow(
                    title: l10n.moreTerms,
                    titleStyle: AppText.body,
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    minHeight: 56,
                    showDivider: AppConfig.privacyUrl.isNotEmpty,
                    onTap: () => launchUrl(
                      Uri.parse(AppConfig.termsUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                if (AppConfig.privacyUrl.isNotEmpty)
                  LedgerRow(
                    title: l10n.morePrivacy,
                    titleStyle: AppText.body,
                    trailing: const Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    minHeight: 56,
                    showDivider: false,
                    onTap: () => launchUrl(
                      Uri.parse(AppConfig.privacyUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: AppSpace.x12),

          // Section 4: Sign out sheet
          LedgerSheet(
            children: [
              LedgerRow(
                title: l10n.actionSignOut,
                titleStyle: AppText.body,
                titleColor: AppColors.overdueFg,
                minHeight: 56,
                showDivider: false,
                onTap: () => _handleSignOut(context, ref, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
