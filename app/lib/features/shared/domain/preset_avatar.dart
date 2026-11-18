import 'package:flutter/widgets.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/tokens.dart';

class PresetAvatar {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const PresetAvatar({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = AppColors.surface,
  });

  static const List<PresetAvatar> all = [
    PresetAvatar(
      id: 'avatar_user',
      label: 'Classic',
      icon: AppIcons.user,
      backgroundColor: AppColors.avatarPetrol,
    ),
    PresetAvatar(
      id: 'avatar_home',
      label: 'Home',
      icon: AppIcons.home,
      backgroundColor: AppColors.avatarGreen,
    ),
    PresetAvatar(
      id: 'avatar_building',
      label: 'Building',
      icon: AppIcons.building,
      backgroundColor: AppColors.avatarOrange,
    ),
    PresetAvatar(
      id: 'avatar_room',
      label: 'Room',
      icon: AppIcons.room,
      backgroundColor: AppColors.avatarPurple,
    ),
    PresetAvatar(
      id: 'avatar_bed',
      label: 'Stay',
      icon: AppIcons.bed,
      backgroundColor: AppColors.avatarTeal,
    ),
    PresetAvatar(
      id: 'avatar_profile',
      label: 'Guest',
      icon: AppIcons.profile,
      backgroundColor: AppColors.avatarRed,
    ),
  ];

  static PresetAvatar? getById(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

