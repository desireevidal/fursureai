import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/breed_info/data/breed_info.dart';
import 'package:fursure/features/prediction/data/breed_result.dart';

import 'prediction_info_sheet.dart';

class BreedResultCard extends StatelessWidget {
  const BreedResultCard({super.key, required this.result});

  final BreedResult result;

  @override
  Widget build(BuildContext context) {
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
              const Label('Breeds', variant: LabelVariant.h3),
              PredictionInfoBadge(
                accuracyText:
                    'Accuracy: ${(result.confidence * 100).toStringAsFixed(2)}%',
              ),
            ],
          ),
          SizedBox(height: context.spacing.m),
          _BreedRow(
            breed: result.breed,
            confidence: result.primaryDisplayShare,
          ),
          if (result.shouldShowSecondary) ...[
            SizedBox(height: context.spacing.sm),
            _BreedRow(
              breed: result.secondaryBreed!,
              confidence: result.secondaryDisplayShare,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreedRow extends StatelessWidget {
  const _BreedRow({
    required this.breed,
    required this.confidence,
  });

  final String breed;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brand = context.brand;
    final breedInfo = findBreedInfo(breed);
    final displayBreed = normalizeBreedName(breed) == 'puspin'
        ? 'Domestic Shorthair (Puspin)'
        : breed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: ClipOval(
                child: breedInfo != null
                    ? Transform.scale(
                        scale: breedInfo.thumbnailScale,
                        alignment: breedInfo.thumbnailAlignment,
                        child: Image.asset(
                          breedInfo.imageAssetPath,
                          fit: BoxFit.cover,
                          alignment: breedInfo.thumbnailAlignment,
                          errorBuilder: (context, error, _) => Icon(
                            Icons.pets,
                            color: brand.purple,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(Icons.pets, color: brand.purple, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    displayBreed,
                    variant: LabelVariant.subtitle,
                    weight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: context.radius.xs,
                          child: LinearProgressIndicator(
                            value: confidence.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(brand.pink),
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Label(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        variant: LabelVariant.body,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
