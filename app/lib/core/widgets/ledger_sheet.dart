import 'package:flutter/widgets.dart';
import '../theme/tokens.dart';

class LedgerSheet extends StatelessWidget {
  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  const LedgerSheet({
    super.key,
    this.child,
    this.children,
    this.padding,
    this.margin = const EdgeInsets.only(bottom: AppSpace.x12),
  }) : assert(child != null || children != null, 'Either child or children must be provided');

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (children != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children!,
      );
    } else {
      content = child!;
    }

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Container(
      margin: margin,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.hairline,
            width: AppSize.hairline,
          ),
        ),
      ),
      child: content,
    );
  }
}

