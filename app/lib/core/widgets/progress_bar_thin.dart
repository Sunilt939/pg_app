import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

class ProgressBarThin extends StatelessWidget {
  final double progress;

  const ProgressBarThin({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth * clamped,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.petrol,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}

