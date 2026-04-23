import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';
import 'audio_player_pill.dart';

class ScanPreviewStep extends StatelessWidget {
  const ScanPreviewStep({
    super.key,
    required this.selectedImage,
    required this.audioPath,
    required this.onConfirm,
    required this.onRetake,
    required this.onBack,
  });

  final File? selectedImage;
  final String? audioPath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final purpleHeight = screenHeight * 0.44;
    final circleSize = (screenWidth * 0.58).clamp(160.0, 240.0);
    final brand = context.brand;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final spacing = context.spacing;

    return AppPage(
      horizontalPadding: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: purpleHeight,
            child: Container(
              color: brand.purple,
              padding: EdgeInsets.fromLTRB(0, topPad + spacing.sm, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBackButton(onPressed: onBack, color: onPrimary),
                  SizedBox(height: spacing.lg),
                  Center(
                    child: Label(
                      'Almost there!',
                      variant: LabelVariant.h1,
                      color: onPrimary,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: spacing.m),
                  Center(
                    child: Label(
                      'Is the meow and the pic from the\nsame adorable cat?',
                      variant: LabelVariant.subtitle,
                      color: onPrimary,
                      align: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: purpleHeight - circleSize / 2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: EdgeInsets.all(spacing.xs),
                child: ClipOval(
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: purpleHeight + circleSize / 2 + spacing.lg,
            left: spacing.xl,
            right: spacing.xl,
            child: AudioPlayerPill(audioPath: audioPath),
          ),
          Positioned(
            bottom: bottomPad + spacing.lg,
            left: spacing.lg,
            right: spacing.lg,
            child: Row(
              children: [
                Expanded(
                  child: Button(
                    label: 'No',
                    variant: ButtonVariant.outlined,
                    onPressed: onRetake,
                  ),
                ),
                SizedBox(width: spacing.m),
                Expanded(
                  child: Button(
                    label: 'Yes',
                    variant: ButtonVariant.primary,
                    onPressed: onConfirm,
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
