import 'package:flutter/material.dart';

/// Container for [StatefulShellRoute] branch navigators that provides
/// directional slide + fade transitions when switching branches.
class AnimatedBranchContainer extends StatefulWidget {
  /// Creates an [AnimatedBranchContainer].
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  /// The index (in [children]) of the branch navigator to display.
  final int currentIndex;

  /// The branch navigator widgets to display in this container.
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with TickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 300);
  static const Curve _curve = Curves.easeInOut;

  late final List<AnimationController> _controllers;
  late final List<CurvedAnimation> _curved;

  // Track previous index to determine slide direction.
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (i) {
      return AnimationController(
        vsync: this,
        duration: _duration,
        value: i == widget.currentIndex ? 1.0 : 0.0,
      );
    });
    _curved = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: _curve))
        .toList();
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final curved in _curved) {
      curved.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final (index, navigator) in widget.children.indexed)
          _BranchTransition(
            animation: _curved[index],
            isActive: index == widget.currentIndex,
            slideFromRight: _slideDirection(index),
            child: navigator,
          ),
      ],
    );
  }

  /// Returns `true` when the branch at [index] should slide from the right,
  /// `false` when it should slide from the left.
  bool _slideDirection(int index) {
    final int previous = _previousIndex ?? 0;
    return index > previous;
  }
}

// ── Branch transition ───────────────────────────────────────────────────────

/// Animates a single branch navigator with a directional slide + fade.
class _BranchTransition extends StatelessWidget {
  const _BranchTransition({
    required this.animation,
    required this.isActive,
    required this.slideFromRight,
    required this.child,
  });

  final Animation<double> animation;
  final bool isActive;
  final bool slideFromRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Slide offset: incoming branch slides from +0.15 or -0.15 to 0.
    // Outgoing branch slides from 0 to -0.15 or +0.15.
    final double direction = slideFromRight ? 1.0 : -1.0;
    final Tween<Offset> slideTween = Tween<Offset>(
      begin: Offset(direction * 0.15, 0.0),
      end: Offset.zero,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double t = animation.value;
        final Offset offset = slideTween.transform(t);

        return FractionalTranslation(
          translation: offset,
          child: Opacity(
            opacity: t,
            child: IgnorePointer(
              ignoring: !isActive,
              child: TickerMode(enabled: isActive, child: child),
            ),
          ),
        );
      },
    );
  }
}
