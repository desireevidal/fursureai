import 'package:flutter/widgets.dart';

/// Screen-width tiers that drive responsive scaling across the design system.
///
/// | Tier     | Width       | Spacing | Typography | Layout |
/// |----------|-------------|---------|------------|--------|
/// | xs       | < 360 px    | 0.85    | 0.90       | 0.85   |
/// | s        | 360–389 px  | 0.92    | 0.95       | 0.92   |
/// | standard | 390–429 px  | 1.0     | 1.0        | 1.0    |
/// | large    | >= 430 px   | 1.08    | 1.05       | 1.10   |
enum ScreenTier {
  xs,
  s,
  standard,
  large;

  /// Determine the tier from the current [BuildContext].
  static ScreenTier of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return ScreenTier.xs;
    if (width < 390) return ScreenTier.s;
    if (width < 430) return ScreenTier.standard;
    return ScreenTier.large;
  }

  /// Multiplier applied to spacing tokens.
  static double spacingFactor(ScreenTier tier) => switch (tier) {
    ScreenTier.xs => 0.85,
    ScreenTier.s => 0.92,
    ScreenTier.standard => 1.0,
    ScreenTier.large => 1.08,
  };

  /// Multiplier applied to font sizes.
  static double typographyFactor(ScreenTier tier) => switch (tier) {
    ScreenTier.xs => 0.90,
    ScreenTier.s => 0.95,
    ScreenTier.standard => 1.0,
    ScreenTier.large => 1.05,
  };

  /// Multiplier applied to layout constants (icon sizes, containers, etc.).
  static double layoutFactor(ScreenTier tier) => switch (tier) {
    ScreenTier.xs => 0.85,
    ScreenTier.s => 0.92,
    ScreenTier.standard => 1.0,
    ScreenTier.large => 1.10,
  };
}
