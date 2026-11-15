/// Formats phone numbers according to UI Design System Section 9:
/// - Country code +91 followed by groups of 5: "+91 98765 43210"
abstract final class PhoneFormat {
  static const countryCode = '+91';

  /// Extracts digits only from [raw].
  static String extractDigits(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  /// Formats a phone number into "+91 XXXXX XXXXX":
  /// e.g. "+919876543210" -> "+91 98765 43210"
  /// e.g. "9876543210" -> "+91 98765 43210"
  static String format(String raw) {
    final digits = extractDigits(raw);

    // If 12 digits starting with 91, extract the 10-digit mobile number
    String tenDigits;
    if (digits.length == 12 && digits.startsWith('91')) {
      tenDigits = digits.substring(2);
    } else if (digits.length >= 10) {
      tenDigits = digits.substring(digits.length - 10);
    } else {
      // Partial number or invalid length, return formatted with whatever is available
      if (digits.length <= 5) {
        return '$countryCode $digits';
      }
      return '$countryCode ${digits.substring(0, 5)} ${digits.substring(5)}';
    }

    final firstFive = tenDigits.substring(0, 5);
    final lastFive = tenDigits.substring(5, 10);
    return '$countryCode $firstFive $lastFive';
  }

  /// Normalizes into "+91XXXXXXXXXX" for Supabase and database storage:
  static String normalize(String raw) {
    final digits = extractDigits(raw);
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '$countryCode$digits';
    }
    if (raw.startsWith('+')) {
      return '+$digits';
    }
    return '$countryCode$digits';
  }

  /// Checks if [raw] is a valid 10-digit Indian mobile number (starts with 6-9).
  static bool isValidIndianMobile(String raw) {
    final digits = extractDigits(raw);
    final tenDigits = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : (digits.length == 10 ? digits : null);

    if (tenDigits == null) return false;
    final firstChar = tenDigits[0];
    return firstChar == '6' || firstChar == '7' || firstChar == '8' || firstChar == '9';
  }
}

