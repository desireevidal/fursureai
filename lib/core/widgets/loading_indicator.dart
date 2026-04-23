import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'label.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: context.spacing.m),
            Label(message!, variant: LabelVariant.body),
          ],
        ],
      ),
    );
  }
}
