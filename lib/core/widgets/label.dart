import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/brand_colors.dart';

/// Typography variants used by [Label].
enum LabelVariant {
  /// Large screen heading.
  h1,

  /// Medium heading.
  h2,

  /// Small heading.
  h3,

  /// Emphasized body text.
  title,

  /// Secondary text below headings.
  subtitle,

  /// Standard body copy.
  body,

  /// Field labels and item names.
  label,

  /// Small metadata text.
  caption,

  /// Small badge text.
  tag,

  /// Button label.
  button,
}

/// Shared text widget that resolves styles from the current theme.
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

  final String text;

  final LabelVariant variant;

  final Color? color;
  final double? size;
  final FontWeight? weight;
  final double? height;
  final double? letterSpacing;
  final FontStyle? fontStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? align;
  final bool? uppercase;
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
