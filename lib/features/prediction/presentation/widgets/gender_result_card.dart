import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/prediction/data/gender_result.dart';
import 'prediction_info_sheet.dart';

class GenderResultCard extends StatelessWidget {
  const GenderResultCard({super.key, required this.result});

  final GenderResult result;

  @override
  Widget build(BuildContext context) {
    final isMale = result.gender.toLowerCase() == 'male';
    final accuracyPct = (result.confidence * 100).toStringAsFixed(2);

    final brand = context.brand;

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: context.radius.m,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Label('Gender', variant: LabelVariant.h3),
              PredictionInfoBadge(
                accuracyText: 'Accuracy: $accuracyPct%',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                isMale ? Icons.male_rounded : Icons.female_rounded,
                color: brand.purple,
                size: 26,
              ),
              SizedBox(width: context.spacing.sm),
              Label(
                result.gender,
                variant: LabelVariant.title,
                weight: FontWeight.w500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
