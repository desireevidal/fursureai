import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/label.dart';

class ScanLoadingStep extends StatelessWidget {
  const ScanLoadingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return AppPage(
      horizontalPadding: false,
      backgroundColor: brand.purple,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: onPrimary),
            SizedBox(height: context.spacing.lg),
            Label(
              'Analyzing your cat\u2026',
              variant: LabelVariant.title,
              color: onPrimary,
              size: 18,
              weight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
