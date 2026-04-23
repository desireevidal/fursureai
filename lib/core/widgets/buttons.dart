import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/brand_colors.dart';
import 'label.dart';

enum ButtonVariant {
  primary,
  secondary,
  gradient,
  ghost,
  outlined,
  destructive,
}

enum ButtonShape { pill, circle }

class Button extends StatelessWidget {
  const Button({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.shape = ButtonShape.pill,
    this.isLoading = false,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.gradientColors,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.border,
    this.shadow = true,
    this.iconSize,
    this.fontSize,
    this.letterSpacing,
    this.semanticLabel,
  }) : assert(
         label != null || icon != null,
         'At least one of label or icon must be provided.',
       );

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonShape shape;
  final bool isLoading;

  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  final List<Color>? gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;

  /// Defines the border for this button.
  /// For secondary/outlined variants this defaults to a 2.0/1.5 purple stroke.
  /// For circle shape and filled variants, no border is drawn unless provided.
  final BorderSide? border;
  final bool shadow;

  final double? iconSize;
  final double? fontSize;
  final double? letterSpacing;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  static const double _defaultHeight = 50.0;
  static const double _defaultCircleSize = 48.0;
  static const double _pillRadius = 25.0;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !isLoading && onPressed != null;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: _buildSurface(context),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final brand = context.brand;
    final fgColor = _resolveForeground(context, brand);
    final content = _buildContent(fgColor, context);

    if (shape == ButtonShape.circle) {
      final size = height ?? _defaultCircleSize;
      return _Surface(
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        color: backgroundColor ?? brand.pink,
        boxBorder: border != null ? Border.fromBorderSide(border!) : null,
        shadow: shadow,
        child: content,
      );
    }

    final h = height ?? _defaultHeight;
    final radius = BorderRadius.circular(_pillRadius);

    switch (variant) {
      case ButtonVariant.primary:
        return _Surface(
          minHeight: h,
          borderRadius: radius,
          color: backgroundColor ?? brand.purple,
          boxBorder: border != null ? Border.fromBorderSide(border!) : null,
          shadow: shadow,
          child: content,
        );

      case ButtonVariant.secondary:
        final side = border ?? BorderSide(color: brand.purple, width: 2.0);
        return _Surface(
          minHeight: h,
          borderRadius: radius,
          boxBorder: Border.fromBorderSide(side),
          child: content,
        );

      case ButtonVariant.gradient:
        return _Surface(
          minHeight: h,
          borderRadius: radius,
          gradient: LinearGradient(
            colors: gradientColors ?? brand.gradient,
            begin: gradientBegin,
            end: gradientEnd,
          ),
          boxBorder: border != null ? Border.fromBorderSide(border!) : null,
          shadow: shadow,
          child: content,
        );

      case ButtonVariant.ghost:
        return _Surface(minHeight: h, child: content);

      case ButtonVariant.outlined:
        final side = border ?? BorderSide(color: brand.purple, width: 1.5);
        return _Surface(
          minHeight: h,
          borderRadius: radius,
          boxBorder: Border.fromBorderSide(side),
          child: content,
        );

      case ButtonVariant.destructive:
        return _Surface(
          minHeight: h,
          borderRadius: radius,
          color: backgroundColor ?? context.brand.softRed,
          boxBorder: border != null ? Border.fromBorderSide(border!) : null,
          shadow: shadow,
          child: content,
        );
    }
  }

  Color _resolveForeground(BuildContext context, BrandColors brand) {
    if (foregroundColor != null) return foregroundColor!;
    final colorScheme = Theme.of(context).colorScheme;
    switch (variant) {
      case ButtonVariant.secondary:
      case ButtonVariant.outlined:
        return border?.color ?? brand.purple;
      case ButtonVariant.ghost:
        return brand.purple;
      case ButtonVariant.destructive:
        return Colors.white;
      default:
        return colorScheme.onPrimary;
    }
  }

  Widget _buildContent(Color color, BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (label == null) {
      return Icon(icon, color: color, size: iconSize ?? 20);
    }

    if (icon == null) {
      return Label(
        label!,
        variant: LabelVariant.button,
        color: color,
        size: fontSize,
        letterSpacing: letterSpacing,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize ?? 18),
        SizedBox(width: context.spacing.sm),
        Label(
          label!,
          variant: LabelVariant.button,
          color: color,
          size: fontSize,
          letterSpacing: letterSpacing,
        ),
      ],
    );
  }
}

// ── Surface ───────────────────────────────────────────────────────────────────

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.width,
    this.height,
    this.minHeight,
    this.color,
    this.gradient,
    this.boxBorder,
    this.borderRadius,
    this.shadow = false,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double? minHeight;
  final Color? color;
  final Gradient? gradient;
  final Border? boxBorder;
  final BorderRadius? borderRadius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.08)
        : colorScheme.shadow.withValues(alpha: 0.25);

    return Container(
      width: width,
      height: height,
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight!)
          : null,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: borderRadius,
        border: boxBorder,
        boxShadow: shadow
            ? [BoxShadow(color: shadowColor, blurRadius: isDark ? 12 : 10)]
            : null,
      ),
      child: Center(child: child),
    );
  }
}
