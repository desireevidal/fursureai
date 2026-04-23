import 'package:flutter/material.dart';

import 'package:fursure/core/widgets/label.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.subtitleSmall,
  });

  final Widget illustration;

  final String title;
  final String subtitle;

  final String? subtitleSmall;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: h * 0.10),
            SizedBox(
              height: h * 0.35,
              child: Center(child: illustration),
            ),
            SizedBox(height: h * 0.06),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Label(
                    title,
                    variant: LabelVariant.h1,
                    color: onPrimary,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Label(
                    subtitle,
                    variant: LabelVariant.subtitle,
                    color: onPrimary,
                    align: TextAlign.center,
                  ),
                  if (subtitleSmall != null) ...[
                    const SizedBox(height: 8),
                    Label(
                      subtitleSmall!,
                      variant: LabelVariant.caption,
                      color: onPrimary,
                      weight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      align: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}
