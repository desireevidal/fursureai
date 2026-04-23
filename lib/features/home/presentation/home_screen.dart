import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/fab_reveal_transition.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/breed_info/data/breed_info.dart';
import 'package:fursure/features/breed_info/presentation/breed_info_screen.dart';

abstract final class _HomeLayout {
  static double heroBackdropHeight(double screenH) =>
      (screenH * 0.55).clamp(300.0, 480.0);
  static double heroOrbSize(double screenW) =>
      (screenW * 0.47).clamp(120.0, 200.0);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double safeAreaTop = MediaQuery.paddingOf(context).top;
          final double screenW = constraints.maxWidth;
          final double screenH = constraints.maxHeight;
          final double backdropH = _HomeLayout.heroBackdropHeight(screenH);
          final lo = context.layout;
          final spacing = context.spacing;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: backdropH,
                child: _HeroBackdrop(screenW: screenW),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - safeAreaTop,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            lo.screenPadH,
                            lo.screenPadV,
                            lo.screenPadH,
                            spacing.lg,
                          ),
                          child: const _HeroSection(),
                        ),
                        const _ContentSurface(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.screenW});

  final double screenW;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final lo = context.layout;
    final orbSize = _HomeLayout.heroOrbSize(screenW);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.pink, brand.purple, brand.deepPurple],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -lo.screenPadV,
            right: -lo.screenPadH,
            child: _HeroOrb(
              size: orbSize,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: orbSize * 0.6,
            left: -40,
            child: _HeroOrb(
              size: orbSize * 0.73,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroTopRow(),
        SizedBox(height: spacing.lg),
        Label(
          'See what your cat might be in seconds.',
          variant: LabelVariant.h1,
          color: Colors.white,
          height: 1.05,
        ),
        SizedBox(height: spacing.m),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Label(
            'Take one clear photo, add a meow if you want extra context, '
            'and get a polished breed and gender readout.',
            variant: LabelVariant.subtitle,
            color: Colors.white.withValues(alpha: 0.86),
            height: 1.35,
          ),
        ),
        SizedBox(height: spacing.m),
        const _HeroScanCard(),
      ],
    );
  }
}

class _HeroTopRow extends StatelessWidget {
  const _HeroTopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandBadge(),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Settings',
          child: _HeaderIconButton(
            icon: Icons.settings_outlined,
            onTap: () => context.push('/home/settings'),
          ),
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    final lo = context.layout;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: lo.screenPadV,
        vertical: lo.screenPadV / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: context.radius.xxl,
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pets_rounded,
            size: lo.iconSizeS,
            color: Colors.white,
          ),
          SizedBox(width: lo.screenPadV / 2),
          Label(
            'FurSure AI',
            variant: LabelVariant.label,
            color: Colors.white,
            letterSpacing: 0.2,
            uppercase: false,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lo = context.layout;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: lo.iconContainerS,
        height: lo.iconContainerS,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, size: lo.iconSizeS, color: Colors.white),
      ),
    );
  }
}

class _HeroScanCard extends StatelessWidget {
  const _HeroScanCard();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;
    final screenW = MediaQuery.sizeOf(context).width;
    final buttonW = (screenW * 0.33).clamp(96.0, 140.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.m,
        vertical: spacing.m - spacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: context.radius.lg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: lo.iconContainerM,
                height: lo.iconContainerM,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: context.radius.m,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: lo.iconSizeM,
                ),
              ),
              SizedBox(width: spacing.m),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Label(
                        'Scan your cat',
                        variant: LabelVariant.title,
                        color: Colors.white,
                        uppercase: false,
                      ),
                      SizedBox(height: spacing.xs),
                      Label(
                        'Clear photo, fast result.',
                        variant: LabelVariant.caption,
                        color: Colors.white.withValues(alpha: 0.72),
                        uppercase: false,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: buttonW,
                child: Button(
                  label: 'Start',
                  onPressed: () => context.push(
                    '/scan',
                    extra: createFabRevealTransitionData(context),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: context.brand.deepPurple,
                  shadow: false,
                  height: 44,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Content Surface ──────────────────────────────────────────────────────────

class _ContentSurface extends StatelessWidget {
  const _ContentSurface();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    final lo = context.layout;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: context.radius.xl.topLeft,
          topRight: context.radius.xl.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          lo.screenPadH,
          spacing.xl,
          lo.screenPadH,
          lo.navBarTotalHeight + lo.screenPadV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _QuickInfoSection(),
            SizedBox(height: spacing.xl),
            const _BreedSection(),
          ],
        ),
      ),
    );
  }
}

class _QuickInfoSection extends StatelessWidget {
  const _QuickInfoSection();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(
          'Simple, guided scanning',
          variant: LabelVariant.h3,
          uppercase: false,
        ),
        SizedBox(height: spacing.sm),
        Label(
          'Everything starts with the hero action above. Capture one clean photo, '
          'optionally add a meow sample, then review saved results here.',
          variant: LabelVariant.body,
          height: 1.5,
        ),
        SizedBox(height: spacing.m),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Clear guidance',
                subtitle: 'Built-in prompts keep the scan flow easy to follow.',
              ),
            ),
            SizedBox(width: lo.screenPadV / 2),
            Expanded(
              child: _InfoCard(
                icon: Icons.folder_open_outlined,
                title: 'Saved results',
                subtitle:
                    'Open previous scans without leaving the home screen.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;

    return Container(
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: context.radius.lg,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: lo.iconContainerS,
            height: lo.iconContainerS,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: context.radius.m,
            ),
            child: Icon(
              icon,
              size: lo.iconSizeS,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: spacing.m),
          Label(title, variant: LabelVariant.title, uppercase: false),
          SizedBox(height: spacing.xs),
          Label(
            subtitle,
            variant: LabelVariant.caption,
            height: 1.4,
            uppercase: false,
          ),
        ],
      ),
    );
  }
}

// ── Breed section ────────────────────────────────────────────────────────────

class _BreedSection extends StatelessWidget {
  const _BreedSection();

  static const List<BreedInfo> _breedInfos = [
    domesticShorthairBreedInfo,
    siameseBreedInfo,
    persianBreedInfo,
    maineCoonBreedInfo,
    russianBlueBreedInfo,
    bombayBreedInfo,
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(
          'Cat breeds',
          variant: LabelVariant.h3,
          uppercase: false,
        ),
        SizedBox(height: spacing.sm),
        Label(
          'Explore breed profiles, traits, and care details.',
          variant: LabelVariant.caption,
          height: 1.4,
          uppercase: false,
        ),
        SizedBox(height: spacing.m),
        Column(
          children: _breedInfos
              .map((BreedInfo info) => _BreedTile(info: info))
              .toList(),
        ),
      ],
    );
  }
}

class _BreedTile extends StatelessWidget {
  const _BreedTile({required this.info});

  final BreedInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;
    final String size = _factValue('Length/Size');
    final String lifespan = _factValue('Lifespan');
    final String origin = _factValue('Origin');

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Semantics(
        button: true,
        label: '${info.name}, $size, $lifespan, $origin',
        child: GestureDetector(
          onTap: () => openBreedInfoScreen(context, info),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: context.radius.lg,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(spacing.m),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BreedThumbnail(info: info),
                  SizedBox(width: spacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Label(
                          info.name,
                          variant: LabelVariant.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          uppercase: false,
                        ),
                        SizedBox(height: spacing.xs),
                        Label(
                          'Size',
                          variant: LabelVariant.caption,
                          color: theme.colorScheme.onSurfaceVariant,
                          uppercase: false,
                        ),
                        Label(
                          size,
                          variant: LabelVariant.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          uppercase: false,
                        ),
                        SizedBox(height: spacing.sm),
                        Label(
                          'Lifespan',
                          variant: LabelVariant.caption,
                          color: theme.colorScheme.onSurfaceVariant,
                          uppercase: false,
                        ),
                        Label(
                          lifespan,
                          variant: LabelVariant.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          uppercase: false,
                        ),
                        SizedBox(height: spacing.sm),
                        Label(
                          'Origin',
                          variant: LabelVariant.caption,
                          color: theme.colorScheme.onSurfaceVariant,
                          uppercase: false,
                        ),
                        Label(
                          origin,
                          variant: LabelVariant.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          uppercase: false,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: lo.iconSizeS,
                      color: theme.colorScheme.onSurfaceVariant,
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

  String _factValue(String label) => info.facts
      .where((BreedFact fact) => fact.label == label)
      .map((BreedFact fact) {
        if (info.id == 'russianblue' && label == 'Origin') {
          return 'Russia';
        }
        return fact.value;
      })
      .firstOrNull ??
      'Unknown';
}

class _BreedThumbnail extends StatelessWidget {
  const _BreedThumbnail({required this.info});

  final BreedInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lo = context.layout;
    final thumbnailSize = lo.iconContainerL + lo.screenPadV;
    final BorderRadius borderRadius = context.radius.m;

    Widget fallback() {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            Icons.pets_rounded,
            size: lo.iconSizeM,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final Widget child = ClipRRect(
      borderRadius: borderRadius,
      child: Transform.scale(
        scale: info.thumbnailScale,
        alignment: info.thumbnailAlignment,
        child: Image.asset(
          info.imageAssetPath,
          fit: BoxFit.cover,
          alignment: info.thumbnailAlignment,
          filterQuality: FilterQuality.medium,
          errorBuilder: (BuildContext context, Object error, StackTrace? _) {
            return fallback();
          },
        ),
      ),
    );

    return SizedBox(
      width: thumbnailSize,
      height: thumbnailSize,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: child,
      ),
    );
  }
}
