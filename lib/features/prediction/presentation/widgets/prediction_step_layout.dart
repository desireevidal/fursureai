import 'package:flutter/material.dart';

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

    return AppPage(
      horizontalPadding: false,
      backgroundColor: context.brand.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 70,
            child: Container(
              color: context.brand.purple,
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
                  Expanded(child: Center(child: illustration)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 30,
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
                    context.spacing.m,
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
