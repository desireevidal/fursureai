import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_spacing.dart';

/// Design-system back button.
///
/// When used inside a custom layout (e.g. prediction screens), set [padded]
/// to `true` (the default) so the button aligns with screen-level padding.
///
/// When placed as `AppBar.leading`, set [padded] to `false` — the `AppBar`
/// handles its own positioning.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.padded = true,
  });

  final VoidCallback? onPressed;
  final Color? color;

  /// Whether to apply screen-level padding around the icon.
  ///
  /// Set to `false` when the parent already handles positioning (e.g. `AppBar`).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;

    final icon = Icon(
      Icons.arrow_back,
      color: color,
      size: lo.iconSizeM,
    );

    final child = padded
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              lo.screenPadH,
              spacing.sm,
              spacing.m,
              spacing.sm,
            ),
            child: icon,
          )
        : icon;

    return Semantics(
      button: true,
      label: 'Go back',
      child: GestureDetector(
        onTap: onPressed ?? () => context.pop(),
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
