import 'package:flutter/widgets.dart';
import '../format/money.dart';
import '../theme/tokens.dart';

/// Renders money figures according to UI Design System Section 5:
/// - Rupee sign at 85% of font size
/// - Indian digit grouping
/// - Decimals only if paise > 0
/// - Minus sign (U+2212) before rupee sign for negative values
/// - Zero shows zero rupees
class Money extends StatelessWidget {
  final int paise;
  final TextStyle? style;
  final Color? color;

  const Money({
    super.key,
    required this.paise,
    this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppText.heading;
    final resolvedStyle = color != null ? baseStyle.copyWith(color: color) : baseStyle;
    final parts = MoneyFormat.split(paise);

    final symbolStyle = AppText.scaleRupeeSymbol(resolvedStyle);

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: [
          if (parts.isNegative)
            const TextSpan(text: MoneyFormat.minusSign),
          TextSpan(
            text: parts.symbol,
            style: symbolStyle,
          ),
          TextSpan(
            text: parts.rupees,
          ),
          if (parts.hasPaise)
            TextSpan(
              text: '.${parts.paise}',
            ),
        ],
      ),
    );
  }
}
