import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/key_value_row.dart';
import '../../../../core/widgets/ledger_sheet.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/preset_avatar.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

  void _showEditNameSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentName,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => _EditNameSheet(
        initialName: currentName,
        onSave: (newName) async {
          await ref.read(profileRepositoryProvider).updateName(newName);
          ref.invalidate(authContextProvider);
          await ref.read(authContextProvider.future);
          if (context.mounted) {
            AppSnack.show(context, message: l10n.profileNameUpdated);
          }
        },
      ),
    );
  }

  void _showEditEmailSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentEmail,
  ) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => _EditEmailSheet(
        initialEmail: currentEmail,
        onSave: (newEmail) async {
          await ref.read(profileRepositoryProvider).updateEmail(newEmail);
          ref.invalidate(authContextProvider);
          await ref.read(authContextProvider.future);
          if (context.mounted) {
            AppSnack.show(context, message: l10n.profileEmailUpdated);
          }
        },
      ),
    );
  }

  void _showPhotoOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final photoState = ref.read(profilePhotoProvider).valueOrNull;
    final hasCustomPhoto = photoState?.hasCustomPhoto ?? false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetContext) => _PhotoOptionsSheet(
        hasCustomPhoto: hasCustomPhoto,
        onSelectPreset: (presetId) async {
          await ref.read(profilePhotoProvider.notifier).setPreset(presetId);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
            AppSnack.show(context, message: l10n.profilePhotoUpdated);
          }
        },
        onPickImage: (source) async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(
            source: source,
            maxWidth: 1080,
            maxHeight: 1080,
            imageQuality: 80,
          );
          if (picked != null) {
            await ref.read(profilePhotoProvider.notifier).setPhoto(picked.path);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
              AppSnack.show(context, message: l10n.profilePhotoUpdated);
            }
          }
        },
        onRemove: () async {
          await ref.read(profilePhotoProvider.notifier).removePhoto();
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
            AppSnack.show(context, message: l10n.profilePhotoRemoved);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authContext = ref.watch(authContextProvider).valueOrNull;
    final canPop = context.canPop() || (authContext?.isOwner ?? false);
    final person = authContext?.person;

    final photoState = ref.watch(profilePhotoProvider).valueOrNull;

    final fullName = person?.fullName?.trim() ?? '';
    final email = person?.email?.trim() ?? '';
    final phone = person?.phone ?? '';
    final formattedPhone = PhoneFormat.format(phone);
    final hasName = fullName.isNotEmpty;
    final hasEmail = email.isNotEmpty;

    ImageProvider? avatarImage;
    if (photoState?.localPhotoPath != null) {
      final file = File(photoState!.localPhotoPath!);
      if (file.existsSync()) {
        avatarImage = FileImage(file);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: canPop
          ? AppTopBar.back(
              title: l10n.profileTitle,
              onLeadingPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RoutePaths.ownerMore);
                }
              },
            )
          : AppTopBar(title: l10n.profileTitle),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.x32),
        children: [
          // Header sheet
          LedgerSheet(
            padding: const EdgeInsets.all(AppSpace.x16),
            child: Row(
              children: [
                ProfileAvatar(
                  size: 72,
                  name: hasName ? fullName : null,
                  image: avatarImage,
                  presetAvatarId: photoState?.presetAvatarId,
                  showEditBadge: true,
                  onTap: () => _showPhotoOptionsSheet(context, ref, l10n),
                ),
                const SizedBox(width: AppSpace.x16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasName ? fullName : l10n.profileNoName,
                        style: hasName ? AppText.title : AppText.secondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.x4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedPhone,
                            style: AppText.secondary,
                          ),
                          const SizedBox(width: AppSpace.x4),
                          const Icon(
                            AppIcons.lock,
                            size: 16,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Your details section
          SectionHeader(title: l10n.profileDetails),
          LedgerSheet(
            children: [
              KeyValueRow(
                label: l10n.profileName,
                value: hasName ? fullName : l10n.profileNoName,
                valueColor: hasName ? null : AppColors.muted,
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                showDivider: true,
                onTap: () => _showEditNameSheet(context, ref, l10n, fullName),
              ),
              KeyValueRow(
                label: l10n.profileEmail,
                value: hasEmail ? email : l10n.profileEmailAdd,
                valueColor: hasEmail ? null : AppColors.petrol,
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.muted,
                ),
                showDivider: true,
                onTap: () => _showEditEmailSheet(context, ref, l10n, email),
              ),
              KeyValueRow(
                label: l10n.profileMobile,
                value: formattedPhone,
                isReadOnly: true,
                showDivider: false,
                onTap: () => AppSnack.show(context, message: l10n.phoneLocked),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.x24),

          // Sign out button
          Center(
            child: AppButton.text(
              label: l10n.actionSignOut,
              textColor: AppColors.overdueFg,
              onPressed: () => _handleSignOut(context, ref, l10n),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoOptionsSheet extends StatelessWidget {
  final bool hasCustomPhoto;
  final ValueChanged<String> onSelectPreset;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onRemove;

  const _PhotoOptionsSheet({
    required this.hasCustomPhoto,
    required this.onSelectPreset,
    required this.onPickImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.profilePhotoTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x4),
          Text(
            l10n.profileDefaultAvatars,
            style: AppText.secondary,
          ),
          const SizedBox(height: AppSpace.x12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PresetAvatar.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x12),
              itemBuilder: (context, index) {
                final preset = PresetAvatar.all[index];
                return GestureDetector(
                  key: ValueKey(preset.id),
                  onTap: () => onSelectPreset(preset.id),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: preset.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      preset.icon,
                      size: 26,
                      color: preset.iconColor,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.x16),
          const Divider(height: 1, color: AppColors.hairline),
          _PhotoActionRow(
            icon: AppIcons.camera,
            label: l10n.photoTake,
            onTap: () => onPickImage(ImageSource.camera),
          ),
          _PhotoActionRow(
            icon: AppIcons.image,
            label: l10n.photoChoose,
            onTap: () => onPickImage(ImageSource.gallery),
          ),
          if (hasCustomPhoto)
            _PhotoActionRow(
              icon: AppIcons.trash,
              label: l10n.photoRemove,
              isDestructive: true,
              onTap: onRemove,
            ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

class _PhotoActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _PhotoActionRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.overdueFg : AppColors.ink;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(width: AppSpace.x16),
            Text(
              label,
              style: AppText.bodyMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String newName) onSave;

  const _EditNameSheet({
    required this.initialName,
    required this.onSave,
  });

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.nameRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSave(name);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.profileName,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: () => _submit(l10n),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          AppTextField(
            label: l10n.profileName,
            controller: _controller,
            errorText: _errorText,
            autofocus: true,
            onChanged: (val) {
              if (_errorText != null && val.trim().isNotEmpty) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}

class _EditEmailSheet extends StatefulWidget {
  final String initialEmail;
  final Future<void> Function(String? newEmail) onSave;

  const _EditEmailSheet({
    required this.initialEmail,
    required this.onSave,
  });

  @override
  State<_EditEmailSheet> createState() => _EditEmailSheetState();
}

class _EditEmailSheetState extends State<_EditEmailSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _controller.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      setState(() => _errorText = l10n.emailInvalid);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await widget.onSave(email.isEmpty ? null : email);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnack.show(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet(
      title: l10n.profileEmail,
      bottomAction: AppButton.primary(
        label: l10n.actionSave,
        loading: _isLoading,
        expand: true,
        onPressed: () => _submit(l10n),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.x8),
          AppTextField(
            label: l10n.profileEmail,
            controller: _controller,
            errorText: _errorText,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              if (_errorText != null) {
                final trimmed = val.trim();
                if (trimmed.isEmpty || _isValidEmail(trimmed)) {
                  setState(() => _errorText = null);
                }
              }
            },
          ),
          const SizedBox(height: AppSpace.x16),
        ],
      ),
    );
  }
}
