import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screen_tier.dart';

/// Theme-aware typography system.
///
/// Defines font metrics (size, weight, height, letter-spacing) for every
/// [LabelVariant]. Colors are intentionally omitted — the [Label] widget
/// resolves color from the current [ColorScheme] or [BrandColors] at render
/// time.
///
/// Access via `Theme.of(context).extension<AppTextStyles>()!` or the
/// convenience getter `context.textStyles`.
///
/// A single [base] instance is registered in both light and dark [ThemeData]
/// because font metrics do not vary by brightness.
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles._({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.caption,
    required this.tag,
    required this.button,
  });

  /// Large screen heading (onboarding titles, scan headings).
  final TextStyle h1;

  /// Medium heading (permission title, cat name, empty-state title).
  final TextStyle h2;

  /// Small heading (card section titles — "Breeds", "Gender").
  final TextStyle h3;

  /// Emphasized body text (list-item titles, card titles).
  final TextStyle title;

  /// Secondary text below headings.
  final TextStyle subtitle;

  /// Standard body copy.
  final TextStyle body;

  /// Field labels and item names.
  final TextStyle label;

  /// Small metadata text (timestamps, accuracy percentages).
  final TextStyle caption;

  /// Tiny uppercase badge / chip text.
  final TextStyle tag;

  /// Button label text.
  final TextStyle button;

  // ── Singleton ──────────────────────────────────────────────────────────────

  static final base = AppTextStyles._(
    h1: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: -0.9,
    ),
    h2: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.285,
    ),
    h3: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
    title: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    subtitle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.033,
    ),
    body: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
    ),
    label: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
    ),
    caption: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
    tag: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
    button: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  // ── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  AppTextStyles copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? tag,
    TextStyle? button,
  }) {
    return AppTextStyles._(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      tag: tag ?? this.tag,
      button: button ?? this.button,
    );
  }

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles._(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      tag: TextStyle.lerp(tag, other.tag, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}

/// Convenience accessor so widgets can write `context.textStyles.h1`.
///
/// Font sizes are scaled by the current [ScreenTier] typography factor.
extension AppTextStylesContext on BuildContext {
  AppTextStyles get textStyles {
    final base = Theme.of(this).extension<AppTextStyles>()!;
    final factor = ScreenTier.typographyFactor(ScreenTier.of(this));
    if (factor == 1.0) return base;
    return base.copyWith(
      h1: base.h1.copyWith(fontSize: base.h1.fontSize! * factor),
      h2: base.h2.copyWith(fontSize: base.h2.fontSize! * factor),
      h3: base.h3.copyWith(fontSize: base.h3.fontSize! * factor),
      title: base.title.copyWith(fontSize: base.title.fontSize! * factor),
      subtitle: base.subtitle.copyWith(
        fontSize: base.subtitle.fontSize! * factor,
      ),
      body: base.body.copyWith(fontSize: base.body.fontSize! * factor),
      label: base.label.copyWith(fontSize: base.label.fontSize! * factor),
      caption: base.caption.copyWith(
        fontSize: base.caption.fontSize! * factor,
      ),
      tag: base.tag.copyWith(fontSize: base.tag.fontSize! * factor),
      button: base.button.copyWith(fontSize: base.button.fontSize! * factor),
    );
  }
}
