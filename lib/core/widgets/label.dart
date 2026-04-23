import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/brand_colors.dart';

/// Semantic typography variants.
///
/// Each variant maps to a [TextStyle] in [AppTextStyles] and a default color
/// resolved from the current [ColorScheme] or [BrandColors].
enum LabelVariant {
  /// Large screen heading — 36px bold (onboarding titles, scan headings).
  h1,

  /// Medium heading — 32px bold (permission title, cat name).
  h2,

  /// Small heading — 18px bold (card section titles).
  h3,

  /// Emphasized body — 16px semi-bold (list-item titles, card titles).
  title,

  /// Secondary text below headings — 15px regular.
  subtitle,

  /// Standard body copy — 14px regular.
  body,

  /// Field labels and item names — 14px medium.
  label,

  /// Small metadata text — 13px (timestamps, accuracy).
  caption,

  /// Tiny uppercase badge / chip — 12px bold, letter-spaced.
  tag,

  /// Button label — 16px semi-bold, uppercase, letter-spaced.
  button,
}

/// A design-system text widget that resolves its style from the current theme.
///
/// ```dart
/// Label('Screen Title', variant: LabelVariant.h1)
/// Label('Details', variant: LabelVariant.body, color: colorScheme.onSurfaceVariant)
/// Label('BREED', variant: LabelVariant.tag)
/// ```
///
/// The base font metrics come from [AppTextStyles] (a [ThemeExtension]).
/// Color is resolved per-variant from [ColorScheme] / [BrandColors], unless
/// the caller provides an explicit [color] override.
///
/// Optional parameters ([size], [weight], [height], [letterSpacing]) are
/// applied on top of the base style via [TextStyle.copyWith].
class Label extends StatelessWidget {
  const Label(
    this.text, {
    super.key,
    this.variant = LabelVariant.body,
    this.color,
    this.size,
    this.weight,
    this.height,
    this.letterSpacing,
    this.fontStyle,
    this.maxLines,
    this.overflow,
    this.align,
    this.uppercase,
    this.semanticsLabel,
  });

  /// The text to display.
  final String text;

  /// Semantic variant that determines base font metrics and default color.
  final LabelVariant variant;

  // ── Optional overrides ───────────────────────────────────────────────────

  /// Overrides the default color resolved from the theme.
  final Color? color;

  /// Overrides font size.
  final double? size;

  /// Overrides font weight.
  final FontWeight? weight;

  /// Overrides line height.
  final double? height;

  /// Overrides letter spacing.
  final double? letterSpacing;

  /// Overrides font style (normal / italic).
  final FontStyle? fontStyle;

  /// Maximum number of lines before truncation.
  final int? maxLines;

  /// How overflowing text is handled.
  final TextOverflow? overflow;

  /// Text alignment.
  final TextAlign? align;

  /// Forces uppercase rendering. Defaults to `true` for [LabelVariant.tag]
  /// and [LabelVariant.button], `false` for all others.
  final bool? uppercase;

  /// Semantic label for accessibility (passed to [Text.semanticsLabel]).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final colorScheme = Theme.of(context).colorScheme;
    final brand = context.brand;

    final baseStyle = _resolveBaseStyle(styles);
    final resolvedColor = color ?? _resolveDefaultColor(colorScheme, brand);

    final effectiveStyle = baseStyle.copyWith(
      color: resolvedColor,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );

    final isUppercase =
        uppercase ??
        (variant == LabelVariant.tag || variant == LabelVariant.button);
    final displayText = isUppercase ? text.toUpperCase() : text;

    return Text(
      displayText,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: align,
      semanticsLabel: semanticsLabel,
    );
  }

  /// Returns the base [TextStyle] for the current [variant].
  TextStyle _resolveBaseStyle(AppTextStyles styles) {
    return switch (variant) {
      LabelVariant.h1 => styles.h1,
      LabelVariant.h2 => styles.h2,
      LabelVariant.h3 => styles.h3,
      LabelVariant.title => styles.title,
      LabelVariant.subtitle => styles.subtitle,
      LabelVariant.body => styles.body,
      LabelVariant.label => styles.label,
      LabelVariant.caption => styles.caption,
      LabelVariant.tag => styles.tag,
      LabelVariant.button => styles.button,
    };
  }

  /// Returns the default color for the current [variant] based on the theme.
  Color _resolveDefaultColor(ColorScheme colorScheme, BrandColors brand) {
    return switch (variant) {
      LabelVariant.h1 ||
      LabelVariant.h2 ||
      LabelVariant.h3 ||
      LabelVariant.title ||
      LabelVariant.body ||
      LabelVariant.label => colorScheme.onSurface,
      LabelVariant.subtitle ||
      LabelVariant.caption => colorScheme.onSurfaceVariant,
      LabelVariant.tag => brand.purple,
      LabelVariant.button => colorScheme.onPrimary,
    };
  }
}
