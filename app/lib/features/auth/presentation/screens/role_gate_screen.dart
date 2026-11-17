import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../providers/auth_provider.dart';

class RoleGateScreen extends ConsumerStatefulWidget {
  const RoleGateScreen({super.key});

  @override
  ConsumerState<RoleGateScreen> createState() => _RoleGateScreenState();
}

class _RoleGateScreenState extends ConsumerState<RoleGateScreen> {
  bool _isSigningOut = false;

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.x48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    AppAssets.logoMark,
                    width: 40,
                    height: 40,
                    placeholderBuilder: (_) =>
                        const SizedBox(width: 40, height: 40),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gateTitle(AppConfig.appName),
                      style: AppText.display,
                    ),
                    const SizedBox(height: AppSpace.x8),
                    Text(
                      l10n.gateSignedInAs(formattedPhone),
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              LedgerSheet(
                margin: EdgeInsets.zero,
                children: [
                  _RoleOptionTile(
                    icon: AppIcons.building,
                    title: l10n.gateOwnerTitle,
                    body: l10n.gateOwnerBody,
                    onTap: () => context.push(RoutePaths.ownerPgNew),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 76),
                    height: AppSize.hairline,
                    color: AppColors.hairline,
                  ),
                  _RoleOptionTile(
                    icon: AppIcons.user,
                    title: l10n.gateGuestTitle,
                    body: l10n.gateGuestBody,
                    onTap: () => context.push(RoutePaths.gateGuest),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x24),
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
      ),
    );
  }
}

class _RoleOptionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _RoleOptionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  State<_RoleOptionTile> createState() => _RoleOptionTileState();
}

class _RoleOptionTileState extends State<_RoleOptionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        color: _isPressed ? AppColors.petrolTint : AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.petrolTint,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: 28,
                color: AppColors.petrol,
              ),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppText.heading,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.body,
                    style: AppText.secondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x12),
            const Icon(
              AppIcons.chevronRight,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
