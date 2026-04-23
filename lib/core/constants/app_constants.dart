// AppConstants has been split:
//   - Runtime config  -> lib/core/config/app_config.dart
//   - ML constants    -> lib/features/prediction/data/prediction_constants.dart

import 'package:flutter/widgets.dart';

import '../theme/screen_tier.dart';

class AppLayout {
  const AppLayout._({
    required this.screenPadH,
    required this.screenPadV,
    required this.avatarSize,
    required this.iconSizeS,
    required this.iconSizeM,
    required this.iconContainerS,
    required this.iconContainerM,
    required this.iconContainerL,
    required this.micButtonSize,
    required this.emptyStateIconSize,
    required this.navBarSideMargin,
    required this.navBarBottomGap,
    required this.navBarPillHeight,
    required this.navBarScanFabSize,
  });

  // Screen-level padding
  final double screenPadH;
  final double screenPadV;

  // Component sizes
  final double avatarSize;
  final double iconSizeS;
  final double iconSizeM;
  final double iconContainerS;
  final double iconContainerM;
  final double iconContainerL;
  final double micButtonSize;
  final double emptyStateIconSize;

  // Nav bar geometry
  final double navBarSideMargin;
  final double navBarBottomGap;
  final double navBarPillHeight;
  final double navBarScanFabSize;

  double get navBarFabOverflow => (navBarScanFabSize - navBarPillHeight) / 2;
  double get navBarTotalHeight =>
      navBarPillHeight + navBarBottomGap + navBarFabOverflow;

  // ── Standard baseline values ───────────────────────────────────────────────

  static const _standard = AppLayout._(
    screenPadH: 20.0,
    screenPadV: 20.0,
    avatarSize: 44.0,
    iconSizeS: 20.0,
    iconSizeM: 24.0,
    iconContainerS: 48.0,
    iconContainerM: 52.0,
    iconContainerL: 56.0,
    micButtonSize: 100.0,
    emptyStateIconSize: 88.0,
    navBarSideMargin: 20.0,
    navBarBottomGap: 16.0,
    navBarPillHeight: 52.0,
    navBarScanFabSize: 72.0,
  );

  factory AppLayout.forTier(ScreenTier tier) {
    final f = ScreenTier.layoutFactor(tier);
    if (f == 1.0) return _standard;
    return AppLayout._(
      screenPadH: _standard.screenPadH * f,
      screenPadV: _standard.screenPadV * f,
      avatarSize: _standard.avatarSize * f,
      iconSizeS: _standard.iconSizeS * f,
      iconSizeM: _standard.iconSizeM * f,
      iconContainerS: _standard.iconContainerS * f,
      iconContainerM: _standard.iconContainerM * f,
      iconContainerL: _standard.iconContainerL * f,
      micButtonSize: _standard.micButtonSize * f,
      emptyStateIconSize: _standard.emptyStateIconSize * f,
      navBarSideMargin: _standard.navBarSideMargin * f,
      navBarBottomGap: _standard.navBarBottomGap * f,
      navBarPillHeight: _standard.navBarPillHeight * f,
      navBarScanFabSize: _standard.navBarScanFabSize * f,
    );
  }
}

extension AppLayoutContext on BuildContext {
  AppLayout get layout => AppLayout.forTier(ScreenTier.of(this));
}
