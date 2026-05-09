import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/core/widgets/error_display.dart';
import 'startup_controller.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final startupAsync = ref.watch(startupControllerProvider);

    startupAsync.whenData((String route) {
      if (_hasNavigated || !mounted) return;
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(route);
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: startupAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (Object error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ErrorDisplay(
              message: error.toString(),
              onRetry: () => ref.invalidate(startupControllerProvider),
            ),
          ),
        ),
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}
