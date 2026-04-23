import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_spacing.dart';
import 'label.dart';

/// Shown when both breed and gender analysis are unavailable.
class UnavailableCard extends StatelessWidget {
  const UnavailableCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withAlpha(90);

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(context.layout.screenPadH),
        child: Row(
          children: [
            Icon(Icons.model_training, color: muted, size: 28),
            SizedBox(width: context.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    'Analysis unavailable',
                    variant: LabelVariant.title,
                    color: muted,
                  ),
                  SizedBox(height: context.spacing.xs),
                  Label(
                    'On-device models are not loaded yet. '
                    'Results will appear here once models are available.',
                    variant: LabelVariant.caption,
                    color: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
