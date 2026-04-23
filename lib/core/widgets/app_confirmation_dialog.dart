import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/brand_colors.dart';
import 'buttons.dart';
import 'label.dart';

Future<bool?> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Delete',
  ButtonVariant confirmVariant = ButtonVariant.primary,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _AppConfirmationDialog(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      confirmVariant: confirmVariant,
    ),
  );
}

class _AppConfirmationDialog extends StatelessWidget {
  const _AppConfirmationDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmVariant,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final ButtonVariant confirmVariant;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final brand = context.brand;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.xl,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.m,
          spacing.lg,
          spacing.lg,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: context.radius.lg,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Label(
              title,
              variant: LabelVariant.title,
              size: 20,
              weight: FontWeight.w800,
              align: TextAlign.center,
              uppercase: false,
            ),
            SizedBox(height: spacing.sm),
            Label(
              message,
              variant: LabelVariant.body,
              align: TextAlign.center,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
              uppercase: false,
            ),
            SizedBox(height: spacing.lg),
            Row(
              children: [
                Expanded(
                  child: Button(
                    label: cancelLabel,
                    variant: ButtonVariant.outlined,
                    fontSize: 13,
                    border: BorderSide(
                      color: colorScheme.outline,
                      width: 1.4,
                    ),
                    foregroundColor: colorScheme.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context, false),
                    shadow: false,
                  ),
                ),
                SizedBox(width: spacing.m),
                Expanded(
                  child: Button(
                    label: confirmLabel,
                    variant: confirmVariant,
                    fontSize: 13,
                    backgroundColor: confirmVariant == ButtonVariant.primary
                        ? brand.pink
                        : null,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
