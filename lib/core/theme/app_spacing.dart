import 'dart:ui';

import 'package:flutter/material.dart';

import 'screen_tier.dart';

/// Spacing tokens used across the app.
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

/// Access spacing tokens from the current context.
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
