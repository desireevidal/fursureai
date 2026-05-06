import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_radius.dart';
import '../theme/brand_colors.dart';
import 'fab_reveal_transition.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final lo = context.layout;
    final surface = Theme.of(context).colorScheme.surface;
    final brand = context.brand;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: lo.navBarTotalHeight + 112,
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.42, 0.70, 1.0],
                          colors: [
                            surface.withValues(alpha: 0.00),
                            surface.withValues(alpha: 0.14),
                            surface.withValues(alpha: 0.72),
                            Color.alphaBlend(
                              brand.purple.withValues(alpha: 0.06),
                              surface.withValues(alpha: 0.97),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: lo.navBarBottomGap - 8,
                    height: lo.navBarScanFabSize + 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            surface.withValues(alpha: 0.00),
                            surface.withValues(alpha: 0.52),
                            surface.withValues(alpha: 0.90),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: lo.navBarSideMargin,
                    right: lo.navBarSideMargin,
                    bottom: lo.navBarBottomGap + 6,
                    height: lo.navBarScanFabSize + 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.55),
                          radius: 0.92,
                          colors: [
                            brand.pink.withValues(alpha: 0.14),
                            brand.purple.withValues(alpha: 0.08),
                            surface.withValues(alpha: 0.00),
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CustomNavBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  navigationShell.goBranch(index, initialLocation: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomNavBar extends StatefulWidget {
  const _CustomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  static const _sideItems = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.bookmark_border_rounded,
      selectedIcon: Icons.bookmark_rounded,
      label: 'My Clawlection',
    ),
  ];

  @override
  State<_CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<_CustomNavBar>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 320);
  static const double _navButtonHorizontalMargin = 8.0;
  static const double _navButtonVerticalMargin = 6.0;

  late final AnimationController _controller;
  late Animation<double> _selectionAnimation;
  late double _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.selectedIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );
    _selectionAnimation = AlwaysStoppedAnimation<double>(_selection);
  }

  @override
  void didUpdateWidget(covariant _CustomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectionAnimation =
          Tween<double>(
            begin: _selection,
            end: widget.selectedIndex.toDouble(),
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOutCubicEmphasized,
            ),
          );
      _controller
        ..value = 0.0
        ..forward();
      _selection = widget.selectedIndex.toDouble();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lo = context.layout;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        lo.navBarSideMargin + 4,
        0,
        lo.navBarSideMargin + 4,
        lo.navBarBottomGap + 4,
      ),
      child: SizedBox(
        height: lo.navBarScanFabSize + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: lo.navBarFabOverflow + 4,
              bottom: lo.navBarFabOverflow + 4,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: context.radius.xxl,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: isDark ? 0.40 : 0.10,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: isDark ? 0.20 : 0.05,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double navItemWidth =
                        (constraints.maxWidth - lo.navBarScanFabSize) / 2;

                    return AnimatedBuilder(
                      animation: _selectionAnimation,
                      builder: (context, _) {
                        final double selection = _selectionAnimation.value;
                        final double indicatorInset =
                            _navButtonHorizontalMargin;
                        final double indicatorWidth =
                            navItemWidth - (indicatorInset * 2);
                        final double indicatorLeft =
                            (selection *
                                (navItemWidth + lo.navBarScanFabSize)) +
                            indicatorInset;

                        return Stack(
                          children: [
                            Positioned(
                              left: indicatorLeft,
                              top: _navButtonVerticalMargin,
                              bottom: _navButtonVerticalMargin,
                              child: IgnorePointer(
                                child: Container(
                                  width: indicatorWidth,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: context.radius.xxl,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: navItemWidth,
                                  child: Semantics(
                                    button: true,
                                    label: _CustomNavBar._sideItems[0].label,
                                    selected: selection < 0.5,
                                    child: _NavButton(
                                      item: _CustomNavBar._sideItems[0],
                                      selectionProgress: _selectionProgressFor(
                                        index: 0,
                                        selection: selection,
                                      ),
                                      onTap: () =>
                                          widget.onDestinationSelected(0),
                                      selectedColor:
                                          colorScheme.onSecondaryContainer,
                                      unselectedColor:
                                          colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                SizedBox(width: lo.navBarScanFabSize),
                                SizedBox(
                                  width: navItemWidth,
                                  child: Semantics(
                                    button: true,
                                    label: _CustomNavBar._sideItems[1].label,
                                    selected: selection >= 0.5,
                                    child: _NavButton(
                                      item: _CustomNavBar._sideItems[1],
                                      selectionProgress: _selectionProgressFor(
                                        index: 1,
                                        selection: selection,
                                      ),
                                      onTap: () =>
                                          widget.onDestinationSelected(1),
                                      selectedColor:
                                          colorScheme.onSecondaryContainer,
                                      unselectedColor:
                                          colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ),
          ),
            Semantics(
              button: true,
              label: 'Scan a cat',
              child: _ScanFab(
                isSelected: false,
                onTap: (transitionData) =>
                    context.push('/scan', extra: transitionData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _selectionProgressFor({
    required int index,
    required double selection,
  }) {
    return (1.0 - (selection - index).abs()).clamp(0.0, 1.0);
  }
}

class _ScanFab extends StatefulWidget {
  const _ScanFab({required this.isSelected, required this.onTap});

  final bool isSelected;
  final ValueChanged<FabRevealTransitionData> onTap;

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab>
    with SingleTickerProviderStateMixin {
  final GlobalKey _fabKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(_ScanFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final RenderBox? renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    widget.onTap(createFabRevealTransitionData(context, renderBox: renderBox));
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = context.layout.navBarScanFabSize;
    final activeSize = baseSize + 10.0;
    final brand = context.brand;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value.clamp(0.0, 1.0);
          final size = baseSize + (activeSize - baseSize) * t;
          final iconSize = 26.0 + 4.0 * t;

          return SizedBox(
            key: _fabKey,
            width: activeSize,
            height: activeSize,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [brand.pink, brand.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brand.purple.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: brand.purple.withValues(alpha: 0.30 * t),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isSelected
                      ? Icons.photo_camera_rounded
                      : Icons.photo_camera_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.75 + 0.25 * t),
                  size: iconSize,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selectionProgress,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final _NavItem item;
  final double selectionProgress;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final double t = selectionProgress.clamp(0.0, 1.0);
    final Color iconColor = Color.lerp(unselectedColor, selectedColor, t)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: context.radius.xxl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.radius.xxl,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return selectedColor.withValues(alpha: 0.06);
            }
            if (states.contains(WidgetState.focused)) {
              return selectedColor.withValues(alpha: 0.08);
            }
            return null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ExcludeSemantics(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1.0 - t,
                    child: Icon(
                      item.icon,
                      size: 24.0 + (2.0 * t),
                      color: iconColor,
                    ),
                  ),
                  Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * t),
                      child: Icon(
                        item.selectedIcon,
                        size: 24.0 + (2.0 * t),
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
