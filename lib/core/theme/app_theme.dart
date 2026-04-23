import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'brand_colors.dart';

class AppTheme {
  static const Color _seed = Color(0xFF7E1891);
  static const Color _pageBackground = Color(0xFFF4F2F4);

  static final CardThemeData _cardTheme = CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: AppRadius().lg),
    elevation: 2,
  );

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      surface: _pageBackground,
    ),
    extensions: [
      BrandColors.light,
      AppTextStyles.base,
      const AppSpacing(),
      const AppRadius(),
    ],
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: _cardTheme,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      titleSpacing: 20.0,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      primary: BrandColors.dark.purple,
      onPrimary: Colors.white,
      secondary: BrandColors.dark.pink,
      onSecondary: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      extensions: [
        BrandColors.dark,
        AppTextStyles.base,
        const AppSpacing(),
        const AppRadius(),
      ],
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: _cardTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleSpacing: 20.0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
