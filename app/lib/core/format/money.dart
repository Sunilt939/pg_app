/// Formats integer paise into Indian Rupee strings.
///
/// Follows UI Design System Section 9:
/// - Rupee sign (₹)
/// - Indian digit grouping: last 3 digits, then groups of 2 (e.g. 1,25,000)
/// - Decimals only if there are paise (e.g. ₹6,500 vs ₹6,500.50)
/// - Zero shows ₹0
/// - Negative amounts show a real minus sign (U+2212) before the rupee sign (e.g. −₹6,500)
abstract final class MoneyFormat {
  static const String rupeeSymbol = '₹';
  static const String minusSign = '\u2212';

  /// Formats an integer using Indian numbering grouping:
  /// e.g. 125000 -> "1,25,000", 6500 -> "6,500"
  static String formatIndianDigits(int value) {
    final s = value.abs().toString();
    if (s.length <= 3) return s;

    final lastThree = s.substring(s.length - 3);
    final remaining = s.substring(0, s.length - 3);
    final buffer = StringBuffer();

    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);
    return buffer.toString();
  }

  /// Formats [paise] into a full Rupee string with symbol:
  /// - 650000 -> "₹6,500"
  /// - 12500000 -> "₹1,25,000"
  /// - 650050 -> "₹6,500.50"
  /// - 0 -> "₹0"
  /// - -650000 -> "−₹6,500"
  /// - -650050 -> "−₹6,500.50"
  static String format(int paise) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final remainingPaise = absPaise % 100;

    final formattedRupees = formatIndianDigits(rupees);
    final prefix = isNegative ? minusSign : '';

    if (remainingPaise == 0) {
      return '$prefix$rupeeSymbol$formattedRupees';
    } else {
      final formattedPaise = remainingPaise.toString().padLeft(2, '0');
      return '$prefix$rupeeSymbol$formattedRupees.$formattedPaise';
    }
  }

  /// Splits [paise] into component parts for custom widget rendering
  /// (e.g. when the rupee sign is rendered at 85% of font size).
  static MoneyParts split(int paise) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final remainingPaise = absPaise % 100;

    return MoneyParts(
      isNegative: isNegative,
      symbol: rupeeSymbol,
      rupees: formatIndianDigits(rupees),
      paise: remainingPaise > 0 ? remainingPaise.toString().padLeft(2, '0') : null,
    );
  }
}

final class MoneyParts {
  final bool isNegative;
  final String symbol;
  final String rupees;
  final String? paise;

  const MoneyParts({
    required this.isNegative,
    required this.symbol,
    required this.rupees,
    this.paise,
  });

  bool get hasPaise => paise != null;
}

String formatRupeesWithGrouping(int rupees) =>
    MoneyFormat.formatIndianDigits(rupees);

