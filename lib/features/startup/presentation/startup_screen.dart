import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/theme/app_text_styles.dart';
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
    final downloadState = ref.watch(downloadProgressProvider);

    startupAsync.whenData((String route) {
      if (_hasNavigated || !mounted) return;
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(route);
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F4),
      body: startupAsync.when(
        loading: () {
          if (downloadState.isComplete) {
            return const _ConfirmationView();
          }
          if (downloadState.isDownloading) {
            return _DownloadProgressView(state: downloadState);
          }
          return const _InitializingView();
        },
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

// ── Initializing (brief pre-download state) ──────────────────────────────────

class _InitializingView extends StatelessWidget {
  const _InitializingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Logo(),
          SizedBox(height: 40),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }
}

// ── Download progress view ───────────────────────────────────────────────────

class _DownloadProgressView extends StatelessWidget {
  const _DownloadProgressView({required this.state});

  final ModelDownloadState state;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final textStyles = context.textStyles;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: const _Logo()),
            const SizedBox(height: 48),
            Text(
              'Setting up FurSure',
              style: textStyles.h2.copyWith(
                color: const Color(0xFF1A1A2E),
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading AI models for the first time.\nThis won\'t happen again.',
              style: textStyles.body.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 40),
            _ModelProgressRow(
              label: 'Breed model',
              icon: Icons.pets,
              progress: state.breedProgress,
              brand: brand,
            ),
            const SizedBox(height: 24),
            _ModelProgressRow(
              label: 'Gender model',
              icon: Icons.record_voice_over,
              progress: state.genderProgress,
              brand: brand,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelProgressRow extends StatelessWidget {
  const _ModelProgressRow({
    required this.label,
    required this.icon,
    required this.progress,
    required this.brand,
  });

  final String label;
  final IconData icon;
  final double progress;
  final BrandColors brand;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final isDone = progress >= 1.0;
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : icon,
              size: 18,
              color: isDone ? Colors.green : brand.purple,
            ),
            const SizedBox(width: 8),
            Text(label, style: textStyles.label.copyWith(color: Colors.black87)),
            const Spacer(),
            Text(
              isDone ? 'Done' : '$percent%',
              style: textStyles.caption.copyWith(
                color: isDone ? Colors.green : brand.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: brand.purple.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? Colors.green : brand.purple,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Confirmation view ────────────────────────────────────────────────────────

class _ConfirmationView extends StatefulWidget {
  const _ConfirmationView();

  @override
  State<_ConfirmationView> createState() => _ConfirmationViewState();
}

class _ConfirmationViewState extends State<_ConfirmationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final textStyles = context.textStyles;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Models ready!',
            style: textStyles.h2.copyWith(
              color: const Color(0xFF1A1A2E),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI models downloaded successfully.\nStarting app…',
            textAlign: TextAlign.center,
            style: textStyles.body.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: brand.purple,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared logo widget ───────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset('assets/images/cat.svg', width: 72, height: 72),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE73879), Color(0xFF7E1891)],
          ).createShader(bounds),
          child: Text(
            'FurSure',
            style: context.textStyles.h2.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
        ),
      ],
    );
  }
}
