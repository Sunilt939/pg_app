import 'package:flutter/material.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'IBMPlexSans',
        scaffoldBackgroundColor: AppColors.ground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.petrol,
          onPrimary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.overdueFg,
        ),
        splashFactory: NoSplash.splashFactory,
        dividerColor: AppColors.hairline,
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: AppColors.petrol),
      );
}

