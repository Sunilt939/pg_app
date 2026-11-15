import 'package:flutter/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final String? name;
  final ImageProvider? image;

  const ProfileAvatar({
    super.key,
    this.size = 72,
    this.name,
    this.image,
  });

  String _initial() {
    if (name == null) return '';
    final trimmed = name!.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Container(
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
    }

    final initial = _initial();

    return Container(
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
}

