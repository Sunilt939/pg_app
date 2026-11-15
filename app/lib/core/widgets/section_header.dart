import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.x16,
        top: AppSpace.x24,
        right: AppSpace.x16,
        bottom: AppSpace.x8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.sectionHeader,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

