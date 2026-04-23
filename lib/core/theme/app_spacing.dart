import 'dart:ui';

import 'package:flutter/material.dart';

import 'screen_tier.dart';

/// Theme-owned spacing tokens.
///
/// Registered as a [ThemeExtension] so spacing stays consistent across
/// the app and responds to theme changes.
///
/// Scale: xs=4, sm=8, m=16, lg=24, xl=32, xxl=40
///
/// Access via `context.spacing.m`.
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.m = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 40,
  });

  final double xs;
  final double sm;
  final double m;
  final double lg;
  final double xl;
  final double xxl;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? m,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      m: m ?? this.m,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      m: lerpDouble(m, other.m, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}

/// Convenience accessor so widgets can write `context.spacing.m`.
///
/// Returns tier-scaled values so all existing `context.spacing.*` calls
/// become responsive without any call-site changes.
extension AppSpacingContext on BuildContext {
  AppSpacing get spacing {
    final base = Theme.of(this).extension<AppSpacing>()!;
    final factor = ScreenTier.spacingFactor(ScreenTier.of(this));
    if (factor == 1.0) return base;
    return AppSpacing(
      xs: base.xs * factor,
      sm: base.sm * factor,
      m: base.m * factor,
      lg: base.lg * factor,
      xl: base.xl * factor,
      xxl: base.xxl * factor,
    );
  }
}
