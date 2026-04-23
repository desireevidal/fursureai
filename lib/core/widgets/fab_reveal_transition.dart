import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/brand_colors.dart';

class FabRevealTransitionData {
  const FabRevealTransitionData({
    required this.center,
    required this.initialRadius,
  });

  final Offset center;

  final double initialRadius;
}

FabRevealTransitionData createFabRevealTransitionData(
  BuildContext context, {
  RenderBox? renderBox,
}) {
  final Size screenSize = MediaQuery.sizeOf(context);
  final EdgeInsets padding = MediaQuery.paddingOf(context);
  final lo = context.layout;
  final Offset fallbackCenter = Offset(
    screenSize.width / 2,
    screenSize.height -
        padding.bottom -
        lo.navBarBottomGap -
        (lo.navBarScanFabSize / 2),
  );
  final Offset center =
      renderBox?.localToGlobal(renderBox.size.center(Offset.zero)) ??
      fallbackCenter;
  final double initialRadius =
      (renderBox?.size.shortestSide ?? lo.navBarScanFabSize) / 2;

  return FabRevealTransitionData(center: center, initialRadius: initialRadius);
}

class FabRevealTransition extends StatelessWidget {
  const FabRevealTransition({
    super.key,
    required this.animation,
    required this.child,
    this.transitionData,
  });

  final Animation<double> animation;
  final Widget child;
  final FabRevealTransitionData? transitionData;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      child: child,
      builder: (context, child) {
        final FabRevealTransitionData? data = transitionData;
        if (data == null || child == null) {
          return child ?? const SizedBox.shrink();
        }

        final Size size = MediaQuery.sizeOf(context);
        final double radius = _maxRadius(size, data);
        final double revealRadius =
            data.initialRadius +
            ((radius - data.initialRadius) * curvedAnimation.value);
        final double contentOpacity = Curves.easeOutCubic.transform(
          Interval(0.16, 1.0).transform(animation.value),
        );
        final _FabRevealClipper clipper = _FabRevealClipper(
          center: data.center,
          radius: revealRadius,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: clipper,
              child: ColoredBox(color: context.brand.purple),
            ),
            ClipPath(
              clipper: clipper,
              child: Opacity(opacity: contentOpacity, child: child),
            ),
          ],
        );
      },
    );
  }

  double _maxRadius(Size size, FabRevealTransitionData origin) {
    final double dx = math.max(origin.center.dx, size.width - origin.center.dx);
    final double dy = math.max(
      origin.center.dy,
      size.height - origin.center.dy,
    );
    return math.sqrt((dx * dx) + (dy * dy)) + origin.initialRadius;
  }
}

class _FabRevealClipper extends CustomClipper<Path> {
  const _FabRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _FabRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}
