import 'package:flutter/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

class RoomTile extends StatelessWidget {
  final String? label;

  const RoomTile({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.trim().isNotEmpty;

    Widget content;
    if (hasLabel) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label!.trim(),
            style: AppText.roomTile,
            maxLines: 1,
          ),
        ),
      );
    } else {
      content = const Icon(
        AppIcons.bed,
        size: AppSize.iconSmall,
        color: AppColors.muted,
      );
    }

    return Container(
      width: AppSize.tile,
      height: AppSize.tile,
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: AppRadius.tile,
        border: Border.all(
          color: AppColors.hairline,
          width: AppSize.hairline,
        ),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

