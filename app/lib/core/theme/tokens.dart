import 'package:flutter/material.dart';

abstract final class AppColors {
  static const transparent = Color(0x00000000);
  static const petrol = Color(0xFF1A4D6B); // actions, active tab, links
  static const petrolPressed = Color(0xFF143D55); // pressed state of petrol
  static const petrolTint = Color(0xFFEDF1F3); // selected option background, pressed rows
  static const ground = Color(0xFFF2F4F6); // app background
  static const surface = Color(0xFFFFFFFF); // sheets, inputs, bars
  static const ink = Color(0xFF1B2631); // main text
  static const muted = Color(0xFF5B6772); // secondary text
  static const hairline = Color(0xFFDDE2E7); // dividers, quiet borders
  static const outline = Color(0xFF7F8A94); // input borders, switch track (meets 3:1)
  static const handle = Color(0xFFC5CCD3); // bottom sheet handle only
  static const disabledBg = Color(0xFFE8ECEF); // disabled buttons
  static const scrim = Color(0xFF0F2A3A); // photo overlay, always at 72% opacity
  static const snackAction = Color(0xFF9CC4DA); // action text on the dark snackbar

  static const paidFg = Color(0xFF187544);
  static const paidBg = Color(0xFFE3F3EA);
  static const pendingFg = Color(0xFF8F5A00);
  static const pendingBg = Color(0xFFFCF0D6);
  static const overdueFg = Color(0xFFB42318);
  static const overdueBg = Color(0xFFFDE8E6);
  static const overduePressed = Color(0xFF912018);

  static const skeletonBase = Color(0xFFE7EBEE);
  static const skeletonHighlight = Color(0xFFF5F7F8);
}

abstract final class AppText {
  static const _f = 'IBMPlexSans';
  // fontSize / line height / weight
  static const display = TextStyle(fontFamily: _f, fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const title = TextStyle(fontFamily: _f, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const heading = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const bodyMedium = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const body = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const secondary = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, color: AppColors.muted);
  static const label = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const caption = TextStyle(fontFamily: _f, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const captionBold = TextStyle(fontFamily: _f, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600);
  static const sectionHeader = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const roomTile = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const button = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);
  static const buttonSmall = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600);

  /// Scales font size down to 85% for the rupee sign in the Money component.
  static TextStyle scaleRupeeSymbol(TextStyle style) {
    final size = style.fontSize ?? 16.0;
    return style.copyWith(fontSize: size * 0.85);
  }
}

abstract final class AppSpace {
  static const double x4 = 4, x8 = 8, x12 = 12, x16 = 16, x24 = 24, x32 = 32, x48 = 48;
  static const double screenPadding = 16;
}

abstract final class AppRadius {
  static const chip = BorderRadius.all(Radius.circular(4));
  static const tile = BorderRadius.all(Radius.circular(6));
  static const control = BorderRadius.all(Radius.circular(8)); // buttons, inputs, option boxes
  static const button = control;
  static const dialog = BorderRadius.all(Radius.circular(12));
  static const sheet = Radius.circular(16);
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(16));
}

abstract final class AppSize {
  static const double topBar = 56, bottomNav = 64, tap = 48, tapInline = 44;
  static const double field = 52, button = 48, rowMin = 64, tile = 44;
  static const double chipMin = 20, hairline = 1;
  static const double icon = 24, iconSmall = 20, iconFeature = 28, iconEmpty = 40;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120); // press feedback
  static const base = Duration(milliseconds: 220); // sheets, state changes
  static const slow = Duration(milliseconds: 350);
  static const tick = Duration(milliseconds: 450); // payment tick drawing
  static const shake = Duration(milliseconds: 320); // wrong code
  static const shimmer = Duration(milliseconds: 1200); // skeleton loop
  static const curve = Curves.easeOutCubic;
}

