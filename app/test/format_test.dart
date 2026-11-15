import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/format/money.dart';
import 'package:app/core/format/phone.dart';
import 'package:app/core/format/dates.dart';
import 'package:app/core/theme/app_icons.dart';

void main() {
  group('MoneyFormat tests', () {
    test('650000 paise gives ₹6,500', () {
      expect(MoneyFormat.format(650000), '₹6,500');
    });

    test('12500000 paise gives ₹1,25,000', () {
      expect(MoneyFormat.format(12500000), '₹1,25,000');
    });

    test('650050 paise gives ₹6,500.50', () {
      expect(MoneyFormat.format(650050), '₹6,500.50');
    });

    test('650005 paise gives ₹6,500.05', () {
      expect(MoneyFormat.format(650005), '₹6,500.05');
    });

    test('0 paise gives ₹0', () {
      expect(MoneyFormat.format(0), '₹0');
    });

    test('Negative whole paise gives −₹6,500', () {
      expect(MoneyFormat.format(-650000), '−₹6,500');
    });

    test('Negative decimal paise gives −₹6,500.50', () {
      expect(MoneyFormat.format(-650050), '−₹6,500.50');
    });

    test('Large Indian number grouping (1 crore rupees from 1000000000 paise)', () {
      expect(MoneyFormat.format(1000000000), '₹1,00,00,000');
    });

    test('MoneyFormat.split splits correctly for custom Money rendering', () {
      final parts = MoneyFormat.split(650050);
      expect(parts.isNegative, false);
      expect(parts.symbol, '₹');
      expect(parts.rupees, '6,500');
      expect(parts.paise, '50');
      expect(parts.hasPaise, true);

      final zeroParts = MoneyFormat.split(0);
      expect(zeroParts.isNegative, false);
      expect(zeroParts.rupees, '0');
      expect(zeroParts.paise, null);
      expect(zeroParts.hasPaise, false);

      final negParts = MoneyFormat.split(-650000);
      expect(negParts.isNegative, true);
      expect(negParts.rupees, '6,500');
      expect(negParts.paise, null);
    });
  });

  group('PhoneFormat tests', () {
    test('+919876543210 shown as +91 98765 43210', () {
      expect(PhoneFormat.format('+919876543210'), '+91 98765 43210');
    });

    test('10-digit number formatted as +91 98765 43210', () {
      expect(PhoneFormat.format('9876543210'), '+91 98765 43210');
    });

    test('12-digit number without + formatted as +91 98765 43210', () {
      expect(PhoneFormat.format('919876543210'), '+91 98765 43210');
    });

    test('normalize formats as +91XXXXXXXXXX', () {
      expect(PhoneFormat.normalize('9876543210'), '+919876543210');
      expect(PhoneFormat.normalize('+919876543210'), '+919876543210');
    });

    test('isValidIndianMobile validates 10 digits starting with 6-9', () {
      expect(PhoneFormat.isValidIndianMobile('9876543210'), true);
      expect(PhoneFormat.isValidIndianMobile('8123456789'), true);
      expect(PhoneFormat.isValidIndianMobile('7123456789'), true);
      expect(PhoneFormat.isValidIndianMobile('6123456789'), true);
      expect(PhoneFormat.isValidIndianMobile('5123456789'), false);
      expect(PhoneFormat.isValidIndianMobile('12345'), false);
    });
  });

  group('DateFormat tests', () {
    test('formatDate outputs "12 Nov 2026"', () {
      final date = DateTime(2026, 11, 12);
      expect(DateFormat.formatDate(date), '12 Nov 2026');
    });

    test('formatShortDate outputs "12 Nov"', () {
      final date = DateTime(2026, 11, 12);
      expect(DateFormat.formatShortDate(date), '12 Nov');
    });

    test('formatMonthYear outputs "November 2026"', () {
      final date = DateTime(2026, 11, 12);
      expect(DateFormat.formatMonthYear(date), 'November 2026');
    });

    test('formatTime outputs 12-hour lower-case am or pm', () {
      expect(DateFormat.formatTime(DateTime(2026, 11, 12, 15, 42)), '3:42 pm');
      expect(DateFormat.formatTime(DateTime(2026, 11, 12, 9, 5)), '9:05 am');
      expect(DateFormat.formatTime(DateTime(2026, 11, 12, 0, 0)), '12:00 am');
      expect(DateFormat.formatTime(DateTime(2026, 11, 12, 12, 0)), '12:00 pm');
    });

    test('formatRelativeTime outputs exact intervals', () {
      final now = DateTime(2026, 11, 12, 12, 0, 0);

      // under 1 min: Just now
      expect(DateFormat.formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now), 'Just now');

      // under 1 hour: {n} min ago
      expect(DateFormat.formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');

      // under 24 hours: {n} h ago
      expect(DateFormat.formatRelativeTime(now.subtract(const Duration(hours: 2)), now: now), '2 h ago');

      // yesterday
      final yesterday = DateTime(2026, 11, 11, 10, 0, 0);
      expect(DateFormat.formatRelativeTime(yesterday, now: now), 'Yesterday');

      // older same year: short date
      final olderSameYear = DateTime(2026, 10, 15, 10, 0, 0);
      expect(DateFormat.formatRelativeTime(olderSameYear, now: now), '15 Oct');

      // older different year: full date
      final olderDiffYear = DateTime(2025, 10, 15, 10, 0, 0);
      expect(DateFormat.formatRelativeTime(olderDiffYear, now: now), '15 Oct 2025');
    });

    test('formatBedAndRoom formats according to section 9', () {
      expect(DateFormat.formatBedAndRoom(room: '101', bed: 'A'), 'Room 101, bed A');
      expect(DateFormat.formatBedAndRoom(bed: 'B'), 'Bed B');
    });
  });

  group('AppIcons tests', () {
    test('All semantic icons are assigned', () {
      expect(AppIcons.home, isNotNull);
      expect(AppIcons.homeFill, isNotNull);
      expect(AppIcons.guests, isNotNull);
      expect(AppIcons.guestsFill, isNotNull);
      expect(AppIcons.payments, isNotNull);
      expect(AppIcons.paymentsFill, isNotNull);
      expect(AppIcons.more, isNotNull);
      expect(AppIcons.moreFill, isNotNull);
      expect(AppIcons.history, isNotNull);
      expect(AppIcons.historyFill, isNotNull);
      expect(AppIcons.profile, isNotNull);
      expect(AppIcons.profileFill, isNotNull);
      expect(AppIcons.back, isNotNull);
      expect(AppIcons.close, isNotNull);
      expect(AppIcons.chevronRight, isNotNull);
      expect(AppIcons.chevronDown, isNotNull);
      expect(AppIcons.chevronLeft, isNotNull);
      expect(AppIcons.add, isNotNull);
      expect(AppIcons.check, isNotNull);
      expect(AppIcons.search, isNotNull);
      expect(AppIcons.bell, isNotNull);
      expect(AppIcons.phone, isNotNull);
      expect(AppIcons.copy, isNotNull);
      expect(AppIcons.share, isNotNull);
      expect(AppIcons.lock, isNotNull);
      expect(AppIcons.clock, isNotNull);
      expect(AppIcons.warning, isNotNull);
      expect(AppIcons.camera, isNotNull);
      expect(AppIcons.image, isNotNull);
      expect(AppIcons.edit, isNotNull);
      expect(AppIcons.trash, isNotNull);
      expect(AppIcons.signOut, isNotNull);
      expect(AppIcons.settings, isNotNull);
      expect(AppIcons.building, isNotNull);
      expect(AppIcons.user, isNotNull);
      expect(AppIcons.bed, isNotNull);
      expect(AppIcons.room, isNotNull);
      expect(AppIcons.bank, isNotNull);
      expect(AppIcons.upi, isNotNull);
      expect(AppIcons.cash, isNotNull);
      expect(AppIcons.calendar, isNotNull);
      expect(AppIcons.rupee, isNotNull);
      expect(AppIcons.filter, isNotNull);
      expect(AppIcons.info, isNotNull);
    });
  });
}
