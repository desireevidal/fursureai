import 'package:flutter/material.dart';

import 'package:fursure/core/widgets/label.dart';

class PermissionItemTile extends StatelessWidget {
  const PermissionItemTile({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.15 : 0.10),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 22,
            child: Icon(icon, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Label(label, variant: LabelVariant.label)),
        ],
      ),
    );
  }
}
