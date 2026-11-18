import 'package:flutter/widgets.dart';
import '../../features/shared/domain/preset_avatar.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final String? name;
  final ImageProvider? image;
  final String? presetAvatarId;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.size = 72,
    this.name,
    this.image,
    this.presetAvatarId,
    this.showEditBadge = false,
    this.onTap,
  });

  String _initial() {
    if (name == null) return '';
    final trimmed = name!.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    if (image != null) {
      avatarWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: image!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (presetAvatarId != null &&
        PresetAvatar.getById(presetAvatarId) != null) {
      final preset = PresetAvatar.getById(presetAvatarId)!;
      avatarWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: preset.backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          preset.icon,
          size: size * 0.48,
          color: preset.iconColor,
        ),
      );
    } else {
      final initial = _initial();
      avatarWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.ground,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.hairline,
            width: AppSize.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: initial.isNotEmpty
            ? Text(
                initial,
                style: AppText.title,
              )
            : const Icon(
                AppIcons.user,
                size: AppSize.iconFeature,
                color: AppColors.muted,
              ),
      );
    }

    if (showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.petrol,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                AppIcons.camera,
                size: 12,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
