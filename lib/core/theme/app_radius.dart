import 'package:flutter/material.dart';

import 'screen_tier.dart';

/// Border-radius tokens used across the app.
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.xs = const BorderRadius.all(Radius.circular(4)),
    this.sm = const BorderRadius.all(Radius.circular(8)),
    this.m = const BorderRadius.all(Radius.circular(16)),
    this.lg = const BorderRadius.all(Radius.circular(24)),
    this.xl = const BorderRadius.all(Radius.circular(32)),
    this.xxl = const BorderRadius.all(Radius.circular(40)),
  });

  final BorderRadius xs;
  final BorderRadius sm;
  final BorderRadius m;
  final BorderRadius lg;
  final BorderRadius xl;
  final BorderRadius xxl;

  @override
  AppRadius copyWith({
    BorderRadius? xs,
    BorderRadius? sm,
    BorderRadius? m,
    BorderRadius? lg,
    BorderRadius? xl,
    BorderRadius? xxl,
  }) {
    return AppRadius(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      m: m ?? this.m,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      xs: BorderRadius.lerp(xs, other.xs, t)!,
      sm: BorderRadius.lerp(sm, other.sm, t)!,
      m: BorderRadius.lerp(m, other.m, t)!,
      lg: BorderRadius.lerp(lg, other.lg, t)!,
      xl: BorderRadius.lerp(xl, other.xl, t)!,
      xxl: BorderRadius.lerp(xxl, other.xxl, t)!,
    );
  }
}

/// Access radius tokens from the current context.
extension AppRadiusContext on BuildContext {
  AppRadius get radius {
    final base = Theme.of(this).extension<AppRadius>()!;
    final factor = ScreenTier.spacingFactor(ScreenTier.of(this));
    if (factor == 1.0) return base;
    return AppRadius(
      xs: BorderRadius.all(Radius.circular(base.xs.topLeft.x * factor)),
      sm: BorderRadius.all(Radius.circular(base.sm.topLeft.x * factor)),
      m: BorderRadius.all(Radius.circular(base.m.topLeft.x * factor)),
      lg: BorderRadius.all(Radius.circular(base.lg.topLeft.x * factor)),
      xl: BorderRadius.all(Radius.circular(base.xl.topLeft.x * factor)),
      xxl: BorderRadius.all(Radius.circular(base.xxl.topLeft.x * factor)),
    );
  }
}
