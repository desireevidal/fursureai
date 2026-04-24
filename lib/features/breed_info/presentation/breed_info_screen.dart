import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/breed_info/data/breed_info.dart';

Future<void> openBreedInfoScreen(BuildContext context, BreedInfo info) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => BreedInfoScreen(info: info),
    ),
  );
}

class BreedInfoScreen extends StatelessWidget {
  const BreedInfoScreen({
    super.key,
    required this.info,
  });

  final BreedInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;
    final onPrimary = theme.colorScheme.onPrimary;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              0,
              topPad + spacing.sm,
              0,
              spacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand.pink, brand.purple, brand.deepPurple],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: onPrimary,
                  ),
                ),
                Label(
                  'About',
                  variant: LabelVariant.title,
                  color: onPrimary,
                  weight: FontWeight.w700,
                  uppercase: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [brand.pink, brand.purple, brand.deepPurple],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: context.radius.xxl.topLeft,
                        topRight: context.radius.xxl.topRight,
                      ),
                      child: Image.asset(
                        info.heroImageAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.lg,
                          spacing.lg,
                          spacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Label(
                              info.name,
                              variant: LabelVariant.h2,
                              align: TextAlign.center,
                              uppercase: false,
                            ),
                            SizedBox(height: spacing.lg),
                            _BreedInfoDetailCard(
                              icon: Icons.pets_rounded,
                              title: 'Description',
                              body: info.description,
                            ),
                            SizedBox(height: spacing.lg),
                            _FactGroupCard(facts: info.facts),
                            SizedBox(height: spacing.lg),
                            _BreedInfoDetailCard(
                              icon: Icons.health_and_safety_outlined,
                              title: 'Health',
                              body: info.health,
                            ),
                            SizedBox(height: spacing.m),
                            _BreedInfoDetailCard(
                              icon: Icons.brush_outlined,
                              title: 'Grooming',
                              body: info.grooming,
                            ),
                            SizedBox(height: spacing.m),
                            _BreedInfoDetailCard(
                              icon: Icons.restaurant_outlined,
                              title: 'Nutrition',
                              body: info.nutrition,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedInfoDetailCard extends StatelessWidget {
  const _BreedInfoDetailCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: context.radius.lg,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brand.pink.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: brand.pink,
            ),
          ),
          SizedBox(width: spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(title, variant: LabelVariant.title, uppercase: false),
                SizedBox(height: spacing.sm),
                Label(
                  body,
                  variant: LabelVariant.body,
                  color: theme.colorScheme.onSurfaceVariant,
                  uppercase: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactGroupCard extends StatelessWidget {
  const _FactGroupCard({required this.facts});

  final List<BreedFact> facts;

  static const List<IconData> _icons = [
    Icons.straighten_rounded,
    Icons.monitor_weight_outlined,
    Icons.favorite_border_rounded,
    Icons.public_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: context.radius.lg,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      child: Column(
        children: [
          for (int i = 0; i < facts.length; i++) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: brand.pink.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icons[i < _icons.length ? i : _icons.length - 1],
                      color: brand.pink,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing.m),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '${facts[i].label}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(text: facts[i].value),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != facts.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}
