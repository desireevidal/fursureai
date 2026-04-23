import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'label.dart';

Future<String?> showAppCatNameDialog(
  BuildContext context, {
  required String initialName,
}) {
  final controller = TextEditingController(text: initialName);

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.spacing.lg,
        vertical: context.spacing.xl,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.spacing.lg,
          context.spacing.lg,
          context.spacing.lg,
          context.spacing.lg,
        ),
        decoration: BoxDecoration(
          color: Theme.of(dialogContext).colorScheme.surface,
          borderRadius: context.radius.lg,
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                dialogContext,
              ).colorScheme.shadow.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Label(
              'Edit Cat Name',
              variant: LabelVariant.title,
              size: 20,
              weight: FontWeight.w800,
              uppercase: false,
            ),
            SizedBox(height: context.spacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter cat name',
              ),
            ),
            SizedBox(height: context.spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
