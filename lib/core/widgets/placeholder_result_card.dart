import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'label.dart';

class PlaceholderResultCard extends StatelessWidget {
  const PlaceholderResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(90);
    final lo = context.layout;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(lo.screenPadH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            SizedBox(height: lo.screenPadH),
            _DummyRow(label: 'Breed', muted: muted),
            SizedBox(height: context.spacing.sm),
            _DummyRow(label: 'Gender', muted: muted),
          ],
        ),
      ),
    );
  }
}

class _DummyRow extends StatelessWidget {
  const _DummyRow({required this.label, required this.muted});

  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Label(label, variant: LabelVariant.body, color: muted),
        ),
        SizedBox(width: context.spacing.m),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: muted.withAlpha(40),
              borderRadius: context.radius.xs,
            ),
          ),
        ),
        SizedBox(width: context.spacing.m),
        Container(
          width: 40,
          height: 14,
          decoration: BoxDecoration(
            color: muted.withAlpha(30),
            borderRadius: context.radius.xs,
          ),
        ),
      ],
    );
  }
}
