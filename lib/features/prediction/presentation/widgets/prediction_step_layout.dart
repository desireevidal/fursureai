import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/label.dart';

class PredictionStepLayout extends StatelessWidget {
  const PredictionStepLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.actions,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget illustration;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final screenW = MediaQuery.sizeOf(context).width;
    final titleFontSize = (screenW * 0.095).clamp(26.0, 40.0);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final lo = context.layout;
    final surfaceOverlap = context.spacing.xl;

    return AppPage(
      horizontalPadding: false,
      backgroundColor: context.brand.purple,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.72;

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: headerHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.brand.purple,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.brand.pink,
                        context.brand.purple,
                        context.brand.deepPurple,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    0,
                    topPad + context.spacing.sm,
                    0,
                    context.spacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppBackButton(
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                            color: onPrimary,
                          ),
                          const Spacer(),
                          if (trailing != null) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                right: lo.screenPadH,
                                top: context.spacing.sm,
                              ),
                              child: trailing!,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: context.spacing.m),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: lo.screenPadH,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Label(
                              title,
                              variant: LabelVariant.h1,
                              color: onPrimary,
                              size: titleFontSize,
                              height: 1.1,
                              align: TextAlign.center,
                            ),
                            SizedBox(height: context.spacing.m),
                            Label(
                              subtitle,
                              variant: LabelVariant.subtitle,
                              color: onPrimary,
                              align: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned(
                              left: -screenW * 0.18,
                              top: screenW * 0.2,
                              child: _SoftCircle(
                                size: screenW * 0.9,
                                color: context.brand.pink.withValues(alpha: 0.16),
                                blurSigma: 24,
                              ),
                            ),
                            Positioned(
                              right: -screenW * 0.12,
                              bottom: screenW * 0.02,
                              child: _SoftCircle(
                                size: screenW * 0.54,
                                color: context.brand.softRed.withValues(alpha: 0.14),
                                blurSigma: 20,
                              ),
                            ),
                            Positioned(
                              right: screenW * 0.1,
                              top: screenW * 0.22,
                              child: _SoftCircle(
                                size: screenW * 0.38,
                                color: Colors.white.withValues(alpha: 0.05),
                                blurSigma: 18,
                              ),
                            ),
                            Center(child: illustration),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: headerHeight - surfaceOverlap,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: context.radius.xxl.topLeft,
                      topRight: context.radius.xxl.topRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        lo.screenPadH,
                        context.spacing.m + surfaceOverlap,
                        lo.screenPadH,
                        lo.screenPadV,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildActions(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildActions() {
    if (actions.isEmpty) return [];
    if (actions.length == 1) return [actions.first];

    final separated = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      separated.add(actions[i]);
      if (i < actions.length - 1) {
        separated.add(const _OrDivider());
      }
    }
    return separated;
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({
    required this.size,
    required this.color,
    required this.blurSigma,
  });

  final double size;
  final Color color;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Label(
          'or',
          variant: LabelVariant.subtitle,
          weight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
