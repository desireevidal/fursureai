import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'buttons.dart';
import 'label.dart';

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: spacing.m),
            Label(
              message,
              variant: LabelVariant.body,
              size: 16,
              align: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: spacing.m),
              Button(label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
