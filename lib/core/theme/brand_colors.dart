import 'package:flutter/material.dart';

/// App brand colors.
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.purple,
    required this.pink,
    required this.deepPurple,
    required this.softRed,
    required this.gradient,
  });

  final Color purple;
  final Color pink;
  final Color deepPurple;
  final Color softRed;
  final List<Color> gradient;

  static const light = BrandColors(
    purple: Color(0xFF7E1891),
    pink: Color(0xFFE73879),
    deepPurple: Color(0xFF911880),
    softRed: Color(0xFFD94A6B),
    gradient: [Color(0xFFE73879), Color(0xFF911880)],
  );

  static const dark = BrandColors(
    purple: Color(0xFFB832C8),
    pink: Color(0xFFE73879),
    deepPurple: Color(0xFF871588),
    softRed: Color(0xFFD94A6B),
    gradient: [Color(0xFFE73879), Color(0xFF871588)],
  );

  @override
  BrandColors copyWith({
    Color? purple,
    Color? pink,
    Color? deepPurple,
    Color? softRed,
    List<Color>? gradient,
  }) {
    return BrandColors(
      purple: purple ?? this.purple,
      pink: pink ?? this.pink,
      deepPurple: deepPurple ?? this.deepPurple,
      softRed: softRed ?? this.softRed,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      purple: Color.lerp(purple, other.purple, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      deepPurple: Color.lerp(deepPurple, other.deepPurple, t)!,
      softRed: Color.lerp(softRed, other.softRed, t)!,
      gradient: [
        Color.lerp(gradient[0], other.gradient[0], t)!,
        Color.lerp(gradient[1], other.gradient[1], t)!,
      ],
    );
  }
}

/// Access brand colors from the current context.
extension BrandColorsContext on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
}
