import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/breed_info/data/breed_info.dart';
import 'package:fursure/features/breed_info/presentation/breed_info_screen.dart';

class BreedInfoPreviewList extends StatelessWidget {
  const BreedInfoPreviewList({
    super.key,
    required this.rawBreed,
  });

  final String? rawBreed;

  @override
  Widget build(BuildContext context) {
    final breedInfos = resolveBreedInfos(rawBreed);
    final spacing = context.spacing;

    if (breedInfos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (int i = 0; i < breedInfos.length; i++) ...[
          _BreedInfoPreviewCard(info: breedInfos[i]),
          if (i != breedInfos.length - 1) SizedBox(height: spacing.m),
        ],
      ],
    );
  }
}

class _BreedInfoPreviewCard extends StatelessWidget {
  const _BreedInfoPreviewCard({required this.info});

  final BreedInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final borderRadius = context.radius.m;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => openBreedInfoScreen(context, info),
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(info.name, variant: LabelVariant.h3, uppercase: false),
                  SizedBox(height: spacing.m),
                  Label(
                    info.description,
                    variant: LabelVariant.body,
                    color: theme.colorScheme.onSurfaceVariant,
                    uppercase: false,
                  ),
                  SizedBox(height: spacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.xs,
                        vertical: spacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Label(
                            'Learn more',
                            variant: LabelVariant.caption,
                            color: theme.colorScheme.primary,
                            uppercase: false,
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
