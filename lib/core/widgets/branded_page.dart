import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_page.dart';
import 'screen_header.dart';

/// A page layout with a branded [ScreenHeader] fixed at the top.
///
/// Wraps [AppPage] internally to provide the [Scaffold], background colour,
/// and bottom-nav [MediaQuery] clearance. The [child] is placed below the
/// header inside an [Expanded] widget.
class BrandedPage extends StatelessWidget {
  const BrandedPage({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = true,
    this.hasBottomNav = false,
    this.horizontalPadding = true,
    this.actions,
    this.showSurfaceCap = false,
    this.useGradientHeader = false,
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final bool hasBottomNav;
  final bool horizontalPadding;
  final List<Widget>? actions;
  final bool showSurfaceCap;
  final bool useGradientHeader;

  @override
  Widget build(BuildContext context) {
    final overlap = context.radius.xl.topLeft.x;
    final inset = context.spacing.sm;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final body = horizontalPadding
        ? Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.layout.screenPadH,
            ),
            child: child,
          )
        : child;

    return AppPage(
      hasBottomNav: hasBottomNav,
      horizontalPadding: false,
      child: Column(
        children: [
          ScreenHeader(
            title: title,
            showBackButton: showBackButton,
            actions: actions,
            bottomInset: showSurfaceCap ? overlap : 0,
            useGradient: useGradientHeader,
          ),
          Expanded(
            child: showSurfaceCap
                ? Transform.translate(
                    offset: Offset(0, -overlap),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.only(
                          topLeft: context.radius.xxl.topLeft,
                          topRight: context.radius.xxl.topRight,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: EdgeInsets.only(top: inset),
                        child: body,
                      ),
                    ),
                  )
                : body,
          ),
        ],
      ),
    );
  }
}
