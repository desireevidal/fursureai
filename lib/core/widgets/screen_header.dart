import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../theme/brand_colors.dart';
import 'app_back_button.dart';
import 'label.dart';

/// Header bar used at the top of feature screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.bottomInset = 0,
    this.useGradient = false,
  });

  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double bottomInset;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final brand = context.brand;

    return Semantics(
      header: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: useGradient ? null : brand.purple,
          gradient: useGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.pink, brand.purple, brand.deepPurple],
                )
              : null,
        ),
        padding: EdgeInsets.fromLTRB(
          0,
          topPad + context.spacing.sm,
          0,
          context.spacing.sm + bottomInset,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: showBackButton,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(
                  onPressed: showBackButton ? () => context.pop() : null,
                  color: onPrimary,
                ),
              ),
            ),
            Label(title, variant: LabelVariant.title, color: onPrimary),
            if (actions != null)
              Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
          ],
        ),
      ),
    );
  }
}
