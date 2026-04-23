import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToPermissions();
    }
  }

  void _goToPermissions() => context.go('/permissions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.purple,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                OnboardingPage(
                  illustration: SvgPicture.asset('assets/images/cat.svg'),
                  title: 'Welcome to\nFurSure AI!',
                  subtitle:
                      "Your cat's new favorite app. Just snap, meow, and discover the magic!",
                ),
                OnboardingPage(
                  illustration: SvgPicture.asset(
                    'assets/images/breed_illustration.svg',
                  ),
                  title: 'Guess the Breed',
                  subtitle:
                      "Take a photo and let our smart kitty-detecting AI reveal your cat's origins.",
                  subtitleSmall:
                      'Supported breeds include Domestic Shorthair (Puspin), Persian, Siamese, Maine Coon, Russian Blue, and Bombay.',
                ),
                OnboardingPage(
                  illustration: SvgPicture.asset(
                    'assets/images/cat_record_illustration.svg',
                  ),
                  title: "Male or Female?\nLet's Find Out!",
                  subtitle:
                      'Record a meow or upload a pic. Our AI listens, looks, and gives you the answer.',
                ),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNav(
                currentPage: _currentPage,
                pageCount: _pageCount,
                onSkip: _goToPermissions,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentPage,
    required this.pageCount,
    required this.onSkip,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: context.spacing.xl,
        right: context.spacing.lg,
        bottom: bottomPadding + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Button(
                label: 'Skip',
                variant: ButtonVariant.ghost,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: onSkip,
              ),
              Button(
                icon: Icons.chevron_right_rounded,
                shape: ButtonShape.circle,
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: 20),
          PageIndicator(count: pageCount, current: currentPage),
          SizedBox(height: context.spacing.m),
        ],
      ),
    );
  }
}
