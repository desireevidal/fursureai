import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/label.dart';

enum ScanTipsType { photo, meow }

Future<void> showScanTipsSheet(
  BuildContext context, {
  required ScanTipsType type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScanTipsSheet(type: type),
  );
}

class _ScanTipsSheet extends StatelessWidget {
  const _ScanTipsSheet({required this.type});

  final ScanTipsType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final content = _contentFor(type);

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.m,
            spacing.sm,
            spacing.m,
            spacing.m,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: context.radius.xl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: spacing.sm),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.26,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.m,
                    spacing.m,
                    spacing.m,
                    spacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TipsBadge(type: type),
                      SizedBox(width: spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(
                              content.title,
                              variant: LabelVariant.title,
                              weight: FontWeight.w700,
                              uppercase: false,
                            ),
                            SizedBox(height: spacing.xs),
                            Label(
                              content.subtitle,
                              variant: LabelVariant.caption,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                              uppercase: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(spacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DidYouKnowCard(note: content.didYouKnow),
                        SizedBox(height: spacing.m),
                        if (type == ScanTipsType.photo)
                          const _PhotoGuideExamples(),
                        if (type == ScanTipsType.meow)
                          const _MeowGuideExamples(),
                        SizedBox(height: spacing.m),
                        ...content.sections.map(
                          (section) => Padding(
                            padding: EdgeInsets.only(bottom: spacing.m),
                            child: _TipsSection(section: section),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.m,
                    spacing.xs,
                    spacing.m,
                    spacing.m,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: EdgeInsets.symmetric(vertical: spacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: context.radius.m,
                        ),
                      ),
                      child: const Label(
                        'Close',
                        variant: LabelVariant.body,
                        uppercase: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TipsContent _contentFor(ScanTipsType type) {
    return switch (type) {
      ScanTipsType.photo => const _TipsContent(
        title: 'Photo tips',
        subtitle: 'Use a clear cat photo so the breed scan has the best chance of reading the face and coat details correctly.',
        didYouKnow:
            'FurSure AI predicts based on learned cat breed patterns from supported training data. Clear cat photos usually produce more reliable results.\n\nUnsupported or unclear inputs may still generate predictions based on similar learned features.',
        sections: [
          _TipsSectionData(
            title: 'Keep the scene simple',
            items: [
              _TipsRowData(
                icon: Icons.check_circle_outline_rounded,
                title: 'One cat at a time',
                message:
                    'Try to capture only one cat in the frame so the app knows what to focus on.',
              ),
              _TipsRowData(
                icon: Icons.grid_view_rounded,
                title: 'Reduce clutter',
                message:
                    'Cleaner backgrounds make it easier for the app to focus on the cat instead of the surroundings.',
              ),
              _TipsRowData(
                icon: Icons.filter_none_outlined,
                title: 'No filters or heavy edits',
                message:
                    'Filters, stickers, screenshots, and heavy edits can make the scan less reliable.',
              ),
            ],
          ),
          _TipsSectionData(
            title: 'Before you scan',
            items: [
              _TipsRowData(
                icon: Icons.wb_sunny_outlined,
                title: 'Use bright lighting',
                message:
                    'Natural light or a bright room helps the app see fur color and facial details more clearly.',
              ),
              _TipsRowData(
                icon: Icons.blur_on_outlined,
                title: 'Avoid blur',
                message:
                    'Hold steady and wait for focus. If the photo looks soft or shaky, retake it before scanning.',
              ),
              _TipsRowData(
                icon: Icons.crop_free_rounded,
                title: 'Keep the head inside the frame',
                message:
                    'Do not crop the face too tightly. Leave enough room so the whole head and nearby fur are visible.',
              ),
            ],
          ),
        ],
      ),
      ScanTipsType.meow => const _TipsContent(
        title: 'Meow tips',
        subtitle: 'Use a short, clear meow so the gender scan can focus on the cat vocal sound instead of room noise.',
        didYouKnow:
            'FurSure AI analyzes learned meow patterns from supported audio data. Clear meow recordings usually improve prediction reliability.\n\nNoisy or unsupported sounds may affect prediction results.',
        sections: [
          _TipsSectionData(
            title: 'Make it easy to hear',
            items: [
              _TipsRowData(
                icon: Icons.hearing_rounded,
                title: 'Move closer if needed',
                message:
                    'Stay close enough so the meow is louder than the room noise, but not so close that the audio clips.',
              ),
              _TipsRowData(
                icon: Icons.volume_off_rounded,
                title: 'Choose a quiet place',
                message:
                    'Turn off fans, TV, music, or loud appliances when possible before recording.',
              ),
              _TipsRowData(
                icon: Icons.mic_none_rounded,
                title: 'Stop after the meow',
                message:
                    'Once the meow is captured clearly, stop the recording instead of keeping extra silence or noise.',
              ),
            ],
          ),
          _TipsSectionData(
            title: 'Extra notes',
            items: [
              _TipsRowData(
                icon: Icons.check_circle_outline_rounded,
                title: 'Use an actual meow',
                message:
                    'The clip should contain a real cat meow, not purring, hissing, barking, music, or people talking.',
              ),
              _TipsRowData(
                icon: Icons.replay_rounded,
                title: 'Try again with a cleaner clip',
                message:
                    'A second recording with less background noise usually works better than a longer noisy one.',
              ),
              _TipsRowData(
                icon: Icons.folder_open_outlined,
                title: 'You can also choose a file',
                message:
                    'If you already have a clean meow saved on the device, use Choose from Files instead.',
              ),
            ],
          ),
        ],
      ),
    };
  }
}

const _tipsCatAsset = 'assets/images/cat.svg';
const _tipsSuccessGreen = Color(0xFF2EAD63);

class _DidYouKnowCard extends StatelessWidget {
  const _DidYouKnowCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;

    return Container(
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: context.radius.m,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: brand.purple.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: brand.purple,
              size: 20,
            ),
          ),
          SizedBox(width: spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(
                  'AI Notice',
                  variant: LabelVariant.body,
                  weight: FontWeight.w700,
                  uppercase: false,
                ),
                SizedBox(height: spacing.xs),
                Label(
                  note,
                  variant: LabelVariant.caption,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
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

class _TipsSection extends StatelessWidget {
  const _TipsSection({required this.section});

  final _TipsSectionData section;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: context.radius.m,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(
            section.title,
            variant: LabelVariant.title,
            weight: FontWeight.w700,
            uppercase: false,
          ),
          SizedBox(height: spacing.m),
          ...section.items.asMap().entries.map((entry) {
            final isLast = entry.key == section.items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : spacing.m),
              child: _TipsRow(item: entry.value),
            );
          }),
        ],
      ),
    );
  }
}

class _TipsRow extends StatelessWidget {
  const _TipsRow({required this.item});

  final _TipsRowData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;
    final isWarning = item.icon == Icons.highlight_off_rounded;
    final accent = isWarning ? brand.softRed : brand.purple;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: context.radius.sm,
          ),
          child: Icon(
            item.icon,
            color: accent,
            size: 18,
          ),
        ),
        SizedBox(width: spacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Label(
                item.title,
                variant: LabelVariant.body,
                weight: FontWeight.w700,
                uppercase: false,
              ),
              SizedBox(height: spacing.xs),
              Label(
                item.message,
                variant: LabelVariant.caption,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
                uppercase: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipsBadge extends StatelessWidget {
  const _TipsBadge({required this.type});

  final ScanTipsType type;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brand.pink, brand.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radius.m,
      ),
      child: const Icon(
        Icons.lightbulb_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _PhotoGuideExamples extends StatelessWidget {
  const _PhotoGuideExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _VisualGuideSection(
          title: 'Frame the cat well',
          description:
              'Keep the cat large enough in the frame, with the face shape and facial details easy to see.',
          cards: [
            _VisualGuideCardData(
              title: 'Too small',
              subtitle: 'The cat is too far away.',
              isGood: false,
              kind: _VisualCardKind.photoTooFar,
            ),
            _VisualGuideCardData(
              title: 'Good framing',
              subtitle: 'Keep the face and body clearly visible.',
              isGood: true,
              kind: _VisualCardKind.photoFaceCloseup,
            ),
          ],
        ),
        _VisualGuideSection(
          title: 'Keep the image clear',
          description:
              'Bright, sharp photos usually work better than dark or blurry ones.',
          cards: [
            _VisualGuideCardData(
              title: 'Blurry photo',
              subtitle: 'Retake if details look soft.',
              isGood: false,
              kind: _VisualCardKind.photoBlurry,
            ),
            _VisualGuideCardData(
              title: 'Clear photo',
              subtitle: 'Sharp details are easier to scan.',
              isGood: true,
              kind: _VisualCardKind.photoClear,
            ),
          ],
        ),
      ],
    );
  }
}

class _MeowGuideExamples extends StatelessWidget {
  const _MeowGuideExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _VisualGuideSection(
          title: 'Record a real meow',
          description:
              'The audio scan works best when the cat meow is the clearest sound in the clip.',
          cards: [
            _VisualGuideCardData(
              title: 'Noise or talking',
              subtitle: 'Avoid clips with other loud sounds.',
              isGood: false,
              kind: _VisualCardKind.audioNoise,
            ),
            _VisualGuideCardData(
              title: 'Clear meow',
              subtitle: 'Use the cat meow as the focus.',
              isGood: true,
              kind: _VisualCardKind.audioClearMeow,
            ),
          ],
        ),
        _VisualGuideSection(
          title: 'Keep it short',
          description:
              'A clean 1 to 2 second meow is better than a long noisy recording.',
          cards: [
            _VisualGuideCardData(
              title: 'Too long',
              subtitle: 'Extra noise can weaken the result.',
              isGood: false,
              kind: _VisualCardKind.audioLongClip,
            ),
            _VisualGuideCardData(
              title: '1 to 2 seconds',
              subtitle: 'Short and clear is enough.',
              isGood: true,
              kind: _VisualCardKind.audioShortClip,
            ),
          ],
        ),
      ],
    );
  }
}

class _VisualGuideSection extends StatelessWidget {
  const _VisualGuideSection({
    required this.title,
    required this.description,
    required this.cards,
  });

  final String title;
  final String description;
  final List<_VisualGuideCardData> cards;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: spacing.m),
      padding: EdgeInsets.all(spacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: context.radius.m,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(
            title,
            variant: LabelVariant.title,
            weight: FontWeight.w700,
            uppercase: false,
          ),
          SizedBox(height: spacing.xs),
          Label(
            description,
            variant: LabelVariant.caption,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
            uppercase: false,
          ),
          SizedBox(height: spacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - spacing.m) / 2;
              return Wrap(
                spacing: spacing.m,
                runSpacing: spacing.m,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: cardWidth,
                        child: _VisualGuideCard(card: card),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VisualGuideCard extends StatelessWidget {
  const _VisualGuideCard({required this.card});

  final _VisualGuideCardData card;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: context.radius.m,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualGuidePreview(card: card),
          SizedBox(height: spacing.sm),
          Label(
            card.title,
            variant: LabelVariant.body,
            weight: FontWeight.w700,
            uppercase: false,
          ),
          SizedBox(height: spacing.xs),
          Label(
            card.subtitle,
            variant: LabelVariant.caption,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
            uppercase: false,
          ),
        ],
      ),
    );
  }
}

class _VisualGuidePreview extends StatelessWidget {
  const _VisualGuidePreview({required this.card});

  final _VisualGuideCardData card;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final accent = card.isGood ? _tipsSuccessGreen : brand.softRed;

    return AspectRatio(
      aspectRatio: 1.04,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: context.radius.sm,
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _ExampleScene(kind: card.kind)),
            Positioned(
              right: 8,
              bottom: 8,
              child: _ExampleStatusBadge(isGood: card.isGood),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleScene extends StatelessWidget {
  const _ExampleScene({required this.kind});

  final _VisualCardKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _VisualCardKind.photoTooFar => const _PhotoScene(scale: 0.42),
      _VisualCardKind.photoFaceCloseup => const _PhotoScene(
        scale: 1.12,
        alignment: Alignment(0, 0.18),
      ),
      _VisualCardKind.photoBlurry => _PhotoScene(
        scale: 0.90,
        blurSigma: 2.6,
        overlayColor: Colors.white.withValues(alpha: 0.14),
      ),
      _VisualCardKind.photoClear => const _PhotoScene(
        scale: 0.90,
        showSunBadge: true,
      ),
      _VisualCardKind.audioNoise => const _AudioScene(
        isGood: false,
        shortClip: false,
      ),
      _VisualCardKind.audioClearMeow => const _AudioScene(
        isGood: true,
        shortClip: true,
      ),
      _VisualCardKind.audioLongClip => const _AudioScene(
        isGood: false,
        shortClip: false,
        showDuration: true,
      ),
      _VisualCardKind.audioShortClip => const _AudioScene(
        isGood: true,
        shortClip: true,
        showDuration: true,
      ),
    };
  }
}

class _PhotoScene extends StatelessWidget {
  const _PhotoScene({
    required this.scale,
    this.alignment = Alignment.center,
    this.blurSigma = 0,
    this.overlayColor,
    this.showSunBadge = false,
  });

  final double scale;
  final Alignment alignment;
  final double blurSigma;
  final Color? overlayColor;
  final bool showSunBadge;

  @override
  Widget build(BuildContext context) {
    Widget art = Center(
      child: Transform.scale(
        scale: scale,
        child: Align(
          alignment: alignment,
          child: SvgPicture.asset(_tipsCatAsset),
        ),
      ),
    );

    if (blurSigma > 0) {
      art = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: art,
      );
    }

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF6F9), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(child: art),
        if (overlayColor != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: overlayColor),
            ),
          ),
        if (showSunBadge)
          const Positioned(
            right: 10,
            top: 10,
            child: _CornerIconBadge(
              icon: Icons.wb_sunny_outlined,
              color: Color(0xFFFCC737),
            ),
          ),
      ],
    );
  }
}

class _AudioScene extends StatelessWidget {
  const _AudioScene({
    required this.isGood,
    required this.shortClip,
    this.showDuration = false,
  });

  final bool isGood;
  final bool shortClip;
  final bool showDuration;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final lineColor = isGood
        ? brand.pink
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final badgeColor = isGood ? _tipsSuccessGreen : brand.softRed;

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF8FB), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          bottom: 4,
          child: Transform.scale(
            scale: 0.62,
            alignment: Alignment.bottomCenter,
            child: SvgPicture.asset(_tipsCatAsset),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              shortClip ? 7 : 12,
              (index) => Container(
                width: 5,
                height: shortClip
                    ? 10 + (index % 4) * 6
                    : 8 + ((index + 1) % 5) * 7,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _CornerIconBadge(
            icon: isGood ? Icons.graphic_eq_rounded : Icons.campaign_rounded,
            color: badgeColor,
          ),
        ),
        if (showDuration)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Label(
                shortClip ? '1-2s' : '8s+',
                variant: LabelVariant.caption,
                color: badgeColor,
                weight: FontWeight.w700,
                uppercase: false,
              ),
            ),
          ),
      ],
    );
  }
}

class _CornerIconBadge extends StatelessWidget {
  const _CornerIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _ExampleStatusBadge extends StatelessWidget {
  const _ExampleStatusBadge({required this.isGood});

  final bool isGood;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final color = isGood ? _tipsSuccessGreen : brand.softRed;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isGood ? Icons.check_rounded : Icons.close_rounded,
        color: color,
        size: 18,
      ),
    );
  }
}

class _VisualGuideCardData {
  const _VisualGuideCardData({
    required this.title,
    required this.subtitle,
    required this.isGood,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final bool isGood;
  final _VisualCardKind kind;
}

enum _VisualCardKind {
  photoTooFar,
  photoFaceCloseup,
  photoBlurry,
  photoClear,
  audioNoise,
  audioClearMeow,
  audioLongClip,
  audioShortClip,
}

class _TipsContent {
  const _TipsContent({
    required this.title,
    required this.subtitle,
    required this.didYouKnow,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String didYouKnow;
  final List<_TipsSectionData> sections;
}

class _TipsSectionData {
  const _TipsSectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_TipsRowData> items;
}

class _TipsRowData {
  const _TipsRowData({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class ScanTipsButton extends StatelessWidget {
  const ScanTipsButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open tips',
      child: IconButton(
        onPressed: onTap,
        tooltip: 'Open tips',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        splashRadius: 22,
        icon: const Icon(
          Icons.lightbulb_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
