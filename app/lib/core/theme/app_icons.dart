import 'package:flutter/widgets.dart';

/// Semantic icons contract from UI Design System Section 3.
///
/// Uses standard [IconData] referencing Phosphor font assets from `phosphor_flutter`.
abstract final class AppIcons {
  static const _package = 'phosphor_flutter';
  static const _regular = 'PhosphorRegular';
  static const _fill = 'PhosphorFill';

  // Navigation (Regular & Fill)
  static const IconData home = IconData(0xe2c2, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData homeFill = IconData(0xe2c2, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData guests = IconData(0xe4d6, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData guestsFill = IconData(0xe4d6, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData payments = IconData(0xe3ec, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData paymentsFill = IconData(0xe3ec, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData more = IconData(0xe1fe, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData moreFill = IconData(0xe1fe, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData history = IconData(0xe1a0, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData historyFill = IconData(0xe1a0, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData profile = IconData(0xe4c4, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData profileFill = IconData(0xe4c4, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);

  // Actions & Controls
  static const IconData back = IconData(0xe058, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData close = IconData(0xe4f6, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData chevronRight = IconData(0xe13a, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData chevronDown = IconData(0xe136, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData chevronLeft = IconData(0xe138, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData add = IconData(0xe3d4, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData check = IconData(0xe182, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData search = IconData(0xe30c, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData bell = IconData(0xe0ce, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData phone = IconData(0xe3b8, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData copy = IconData(0xe1ca, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData share = IconData(0xe408, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData lock = IconData(0xe2fa, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData clock = IconData(0xe19a, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData warning = IconData(0xe4e0, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData camera = IconData(0xe10e, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData image = IconData(0xe2ca, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData edit = IconData(0xe3b4, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData trash = IconData(0xe4a6, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData signOut = IconData(0xe42a, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData settings = IconData(0xe270, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData building = IconData(0xe102, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData buildingFill = IconData(0xe102, fontFamily: _fill, fontPackage: _package, matchTextDirection: true);
  static const IconData user = IconData(0xe4c2, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData bed = IconData(0xe0cc, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData room = IconData(0xe61c, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData bank = IconData(0xe0b4, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData upi = IconData(0xe3e6, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData cash = IconData(0xe588, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData calendar = IconData(0xe10a, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData rupee = IconData(0xe558, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData filter = IconData(0xe266, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
  static const IconData info = IconData(0xe2ce, fontFamily: _regular, fontPackage: _package, matchTextDirection: true);
}
