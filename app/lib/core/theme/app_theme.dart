import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        splashFactory: NoSplash.splashFactory,
        dividerColor: AppColors.hairline,
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: AppColors.petrol),
      );
}

