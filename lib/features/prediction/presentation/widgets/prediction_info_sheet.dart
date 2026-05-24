import 'package:flutter/material.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/label.dart';

const String _predictionInfoMessage =
    'FurSure uses separate AI models for breed and gender classification.'
    ' Breed is analyzed from the cat photo, while gender is analyzed from the meow recording.'
    ' Both outputs are displayed together in one cat profile.';

Future<void> showPredictionInfoSheet(BuildContext context) {
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.radius.xl.topLeft.x),
      ),
    ),
    builder: (sheetContext) {
      final spacing = sheetContext.spacing;
      final brand = sheetContext.brand;
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final lo = sheetContext.layout;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.m,
            spacing.sm,
            spacing.m,
            spacing.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label(
                      'How FurSure reads results',
                      variant: LabelVariant.title,
                      size: 20,
                      weight: FontWeight.w700,
                      uppercase: false,
                    ),
                    SizedBox(height: spacing.xs),
                    Label(
                      'Breed comes from the photo, while gender comes from the meow.',
                      variant: LabelVariant.caption,
                      color: colorScheme.onSurfaceVariant,
                      uppercase: false,
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.m),
              Material(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: context.radius.m,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(spacing.m),
                  decoration: BoxDecoration(
                    borderRadius: context.radius.m,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brand.pink, brand.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: context.radius.sm,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: lo.iconSizeS,
                        ),
                      ),
                      SizedBox(width: spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Label(
                              'Unified profile',
                              variant: LabelVariant.body,
                              weight: FontWeight.w600,
                              uppercase: false,
                            ),
                            SizedBox(height: spacing.xs),
                            Label(
                              _predictionInfoMessage,
                              variant: LabelVariant.caption,
                              height: 1.45,
                              color: colorScheme.onSurfaceVariant,
                              uppercase: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.m),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.symmetric(vertical: spacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: context.radius.m,
                    ),
                  ),
                  child: const Label(
                    'Cancel',
                    variant: LabelVariant.body,
                    uppercase: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class PredictionInfoBadge extends StatelessWidget {
  const PredictionInfoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => showPredictionInfoSheet(context),
      borderRadius: context.radius.xl,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.xs,
          vertical: context.spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
