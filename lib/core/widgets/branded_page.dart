import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
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
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final bool hasBottomNav;
  final bool horizontalPadding;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
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
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
