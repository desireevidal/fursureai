import 'package:flutter/material.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';

Future<void> showFirstUseGuide(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'First use guide',
    barrierColor: Colors.transparent,
    pageBuilder: (context, _, _) => const _FirstUseGuideDialog(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _FirstUseGuideDialog extends StatefulWidget {
  const _FirstUseGuideDialog();

  @override
  State<_FirstUseGuideDialog> createState() => _FirstUseGuideDialogState();
}

class _FirstUseGuideDialogState extends State<_FirstUseGuideDialog> {
  static final List<_GuideStep> _steps = [
    _GuideStep(
      anchor: _GuideAnchor.navScan,
      title: 'Start a scan',
      message:
          'Tap the camera button anytime to take a cat photo and begin the scan flow.',
      shape: _SpotlightShape.circle,
      alignToTop: false,
    ),
    _GuideStep(
      anchor: _GuideAnchor.quickStart,
      title: 'Quick start',
      message:
          'This Start button opens the same scan flow right from the home screen.',
      shape: _SpotlightShape.roundedRect,
      alignToTop: false,
    ),
    _GuideStep(
      anchor: _GuideAnchor.navClawlection,
      title: 'Review pawfiles',
      message:
          'Open My Clawlection to search, filter, and manage saved cat results.',
      shape: _SpotlightShape.roundedRect,
      alignToTop: false,
    ),
    _GuideStep(
      anchor: _GuideAnchor.breeds,
      title: 'Browse breed info',
      message:
          'Explore breed profiles, traits, and care details from the cat breeds section.',
      shape: _SpotlightShape.roundedRect,
      alignToTop: true,
    ),
    _GuideStep(
      anchor: _GuideAnchor.settings,
      title: 'Adjust the app',
      message:
          'Use Settings for theme, permissions, and backup or restore tools.',
      shape: _SpotlightShape.circle,
      alignToTop: false,
    ),
  ];

  int _currentIndex = 0;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];
    final screenSize = MediaQuery.sizeOf(context);
    final spacing = context.spacing;
    final targetRect = _resolveTargetRect(step.anchor, screenSize);
    final cardTop = _resolveCardTop(
      screenSize: screenSize,
      targetRect: targetRect,
      spacing: spacing,
      alignToTop: step.alignToTop,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                shape: step.shape,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: spacing.m,
                    right: spacing.m,
                    top: cardTop,
                    child: _GuideCard(
                      index: _currentIndex,
                      total: _steps.length,
                      title: step.title,
                      message: step.message,
                      onSkip: _close,
                      onNext: () {
                        if (_currentIndex == _steps.length - 1) {
                          _close();
                          return;
                        }
                        setState(() => _currentIndex += 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect _resolveTargetRect(_GuideAnchor anchor, Size screenSize) {
    final lo = context.layout;
    final safeTop = MediaQuery.paddingOf(context).top;
    final navBarWidth = screenSize.width - (lo.navBarSideMargin * 2);
    final navBarTop =
        screenSize.height - lo.navBarBottomGap - lo.navBarScanFabSize;
    final navItemWidth = (navBarWidth - lo.navBarScanFabSize) / 2;
    final navBarButtonTop = navBarTop + lo.navBarFabOverflow + 6;
    final navBarButtonHeight =
        lo.navBarScanFabSize - (lo.navBarFabOverflow * 2) - 12;
    final heroCardTop = safeTop + lo.screenPadV + 176;

    return switch (anchor) {
      _GuideAnchor.navScan => Rect.fromCenter(
        center: Offset(screenSize.width / 2, navBarTop + (lo.navBarScanFabSize / 2)),
        width: lo.navBarScanFabSize,
        height: lo.navBarScanFabSize,
      ),
      _GuideAnchor.navClawlection => Rect.fromLTWH(
        lo.navBarSideMargin + navItemWidth + lo.navBarScanFabSize + 8,
        navBarButtonTop,
        navItemWidth - 16,
        navBarButtonHeight,
      ),
      _GuideAnchor.settings => Rect.fromLTWH(
        screenSize.width - lo.screenPadH - lo.iconContainerS,
        safeTop + lo.screenPadV,
        lo.iconContainerS,
        lo.iconContainerS,
      ),
      _GuideAnchor.quickStart => Rect.fromLTWH(
        lo.screenPadH,
        heroCardTop,
        screenSize.width - (lo.screenPadH * 2),
        110,
      ),
      _GuideAnchor.breeds => Rect.fromLTWH(
        lo.screenPadH,
        heroCardTop + 150,
        screenSize.width - (lo.screenPadH * 2),
        150,
      ),
    };
  }

  double _resolveCardTop({
    required Size screenSize,
    required Rect targetRect,
    required AppSpacing spacing,
    required bool alignToTop,
  }) {
    const cardHeight = 230.0;
    final safeTop = MediaQuery.paddingOf(context).top + spacing.sm;
    final safeBottom = screenSize.height - MediaQuery.paddingOf(context).bottom;

    if (alignToTop) {
      final preferred = targetRect.bottom + spacing.lg;
      return preferred.clamp(safeTop, safeBottom - cardHeight);
    }

    final preferred = targetRect.top - cardHeight - spacing.lg;
    if (preferred >= safeTop) {
      return preferred;
    }

    return (targetRect.bottom + spacing.lg).clamp(
      safeTop,
      safeBottom - cardHeight,
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.index,
    required this.total,
    required this.title,
    required this.message,
    required this.onSkip,
    required this.onNext,
  });

  final int index;
  final int total;
  final String title;
  final String message;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;

    return Container(
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: context.radius.xl,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brand.pink, brand.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: context.radius.m,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(
                      'Quick guide',
                      variant: LabelVariant.caption,
                      color: brand.purple,
                      weight: FontWeight.w700,
                    ),
                    Label(
                      title,
                      variant: LabelVariant.title,
                      weight: FontWeight.w700,
                      uppercase: false,
                    ),
                  ],
                ),
              ),
              Label(
                '${index + 1}/$total',
                variant: LabelVariant.caption,
                color: theme.colorScheme.onSurfaceVariant,
                weight: FontWeight.w600,
                uppercase: false,
              ),
            ],
          ),
          SizedBox(height: spacing.m),
          Label(
            message,
            variant: LabelVariant.body,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
            uppercase: false,
          ),
          SizedBox(height: spacing.m),
          Row(
            children: List.generate(
              total,
              (dotIndex) => Container(
                width: dotIndex == index ? 22 : 8,
                height: 8,
                margin: EdgeInsets.only(right: spacing.xs),
                decoration: BoxDecoration(
                  color: dotIndex == index
                      ? brand.purple
                      : brand.purple.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.m),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.sm,
                  ),
                ),
                child: Label(
                  'Skip',
                  variant: LabelVariant.button,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  uppercase: true,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 132,
                child: Button(
                  label: index == total - 1 ? 'Done' : 'Next',
                  onPressed: onNext,
                  variant: ButtonVariant.gradient,
                  height: 46,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.targetRect,
    required this.shape,
  });

  final Rect targetRect;
  final _SpotlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.56);

    final spotlightRect = targetRect.inflate(shape == _SpotlightShape.circle ? 16 : 12);

    final Path overlayPath = Path()..addRect(Offset.zero & size);
    final Path cutoutPath = Path();

    if (shape == _SpotlightShape.circle) {
      cutoutPath.addOval(Rect.fromCircle(
        center: spotlightRect.center,
        radius: spotlightRect.longestSide / 2,
      ));
    } else {
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(24)),
      );
    }

    final Path difference = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );
    canvas.drawPath(difference, overlayPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.92);
    if (shape == _SpotlightShape.circle) {
      canvas.drawOval(
        Rect.fromCircle(
          center: spotlightRect.center,
          radius: spotlightRect.longestSide / 2,
        ),
        strokePaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(24)),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.shape != shape;
  }
}

class _GuideStep {
  const _GuideStep({
    required this.anchor,
    required this.title,
    required this.message,
    required this.shape,
    required this.alignToTop,
  });

  final _GuideAnchor anchor;
  final String title;
  final String message;
  final _SpotlightShape shape;
  final bool alignToTop;
}

enum _SpotlightShape { circle, roundedRect }

enum _GuideAnchor {
  navScan,
  navClawlection,
  settings,
  quickStart,
  breeds,
}
