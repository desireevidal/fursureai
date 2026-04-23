import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_back_button.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.actions,
    this.leading,
    required this.child,
    this.hasBottomNav = false,
    this.horizontalPadding = true,
    this.backgroundColor,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget child;
  final bool hasBottomNav;

  // Set to false for screens with full-bleed content (SliverAppBar, hero images,
  // full-width backgrounds). Those screens manage their own horizontal padding
  // via context.layout.screenPadH.
  final bool horizontalPadding;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final lo = context.layout;

    final body = horizontalPadding
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: lo.screenPadH),
            child: child,
          )
        : child;

    final scaffold = Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              automaticallyImplyLeading: false,
              leading:
                  leading ??
                  (Navigator.canPop(context)
                      ? const AppBackButton(padded: false)
                      : null),
              actions: actions,
            )
          : null,
      body: body,
    );

    if (!hasBottomNav) return scaffold;

    // Inject nav bar clearance into MediaQuery so any ListView or BoxScrollView
    // inside automatically scrolls past the floating nav bar.
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          bottom:
              mq.padding.bottom + lo.navBarTotalHeight + lo.screenPadV,
        ),
      ),
      child: scaffold,
    );
  }
}
