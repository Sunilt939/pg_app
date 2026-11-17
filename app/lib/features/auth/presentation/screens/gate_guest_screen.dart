import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../providers/auth_provider.dart';

class GateGuestScreen extends ConsumerStatefulWidget {
  const GateGuestScreen({super.key});

  @override
  ConsumerState<GateGuestScreen> createState() => _GateGuestScreenState();
}

class _GateGuestScreenState extends ConsumerState<GateGuestScreen> {
  bool _isChecking = false;
  bool _isSigningOut = false;

  Future<void> _copyNumber(String formattedPhone) async {
    await Clipboard.setData(ClipboardData(text: formattedPhone));
    if (mounted) {
      AppSnack.show(
        context,
        message: AppLocalizations.of(context)!.numberCopied,
      );
    }
  }

  Future<void> _checkAgain() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      await ref.read(authContextProvider.notifier).refreshContext();
      if (!mounted) return;
      final authContext = ref.read(authContextProvider).valueOrNull;
      final stays = authContext?.stays ?? [];
      if (stays.isNotEmpty) {
        context.go(RoutePaths.guestHome);
      } else {
        AppSnack.show(
          context,
          message: AppLocalizations.of(context)!.stillNotAdded,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: AppLocalizations.of(context)!.stillNotAdded,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.invalidate(authContextProvider);
      if (mounted) {
        context.go(RoutePaths.signIn);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authContext = ref.watch(authContextProvider).valueOrNull;
    final rawPhone = authContext?.person?.phone ?? '';
    final formattedPhone =
        rawPhone.isNotEmpty ? PhoneFormat.format(rawPhone) : '';

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: const AppTopBar.back(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpace.x24),
                    Text(
                      l10n.guestWaitTitle,
                      style: AppText.title,
                    ),
                    const SizedBox(height: AppSpace.x8),
                    Text(
                      l10n.guestWaitBody,
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              LedgerSheet(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x16,
                  vertical: AppSpace.x16,
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
                            l10n.yourNumber,
                            style: AppText.secondary,
                          ),
                          const SizedBox(height: AppSpace.x4),
                          Text(
                            formattedPhone,
                            style: AppText.title,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Semantics(
                      button: true,
                      label: l10n.yourNumber,
                      child: InkWell(
                        onTap: () => _copyNumber(formattedPhone),
                        borderRadius: AppRadius.button,
                        splashColor: AppColors.transparent,
                        highlightColor: AppColors.petrolTint,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            AppIcons.copy,
                            size: 24,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton.primary(
                      label: l10n.checkAgain,
                      expand: true,
                      loading: _isChecking,
                      onPressed: _checkAgain,
                    ),
                    const SizedBox(height: AppSpace.x12),
                    Center(
                      child: AppButton.text(
                        label: l10n.actionSignOut,
                        loading: _isSigningOut,
                        onPressed: _signOut,
                      ),
                    ),
                    const SizedBox(height: AppSpace.x24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
