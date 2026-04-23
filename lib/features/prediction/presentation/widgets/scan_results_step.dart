import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/core/widgets/unavailable_card.dart';
import 'package:fursure/features/breed_info/presentation/widgets/breed_info_preview_list.dart';
import '../scan_prediction_controller.dart';
import 'package:fursure/features/prediction/data/breed_result.dart';
import 'package:fursure/features/prediction/data/gender_result.dart';
import 'breed_result_card.dart';
import 'gender_result_card.dart';

class ScanResultsStep extends StatelessWidget {
  const ScanResultsStep({
    super.key,
    required this.catName,
    required this.selectedImage,
    required this.predictionResult,
    required this.onEditName,
    required this.onSave,
    required this.onCancel,
  });

  final String catName;
  final File? selectedImage;
  final ScanPredictionResult? predictionResult;
  final VoidCallback onEditName;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    const headerHeight = 88.0;
    final purpleHeight = topPad + headerHeight;
    final circleSize =
        (MediaQuery.sizeOf(context).width * 0.37).clamp(100.0, 150.0);
    final surfaceOverlap = context.radius.xl.topLeft.x;
    final brand = context.brand;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final spacing = context.spacing;
    final lo = context.layout;

    final breedResult = predictionResult?.breedResult;
    final genderResult = predictionResult?.genderResult;

    return AppPage(
      horizontalPadding: false,
      child: Stack(
        children: [
          Positioned(
            top: purpleHeight - surfaceOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: context.radius.xxl.topLeft,
                  topRight: context.radius.xxl.topRight,
                ),
              ),
              clipBehavior: Clip.antiAlias,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: purpleHeight + circleSize / 2 - surfaceOverlap),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      lo.screenPadH,
                      surfaceOverlap + lo.screenPadV,
                      lo.screenPadH,
                      0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Semantics(
                              label: 'Cat name: $catName',
                              child: Label(
                                catName,
                                variant: LabelVariant.h2,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Semantics(
                              button: true,
                              label: 'Edit cat name',
                              child: GestureDetector(
                                onTap: onEditName,
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.m),
                        _TagsRow(
                          breedResult: breedResult,
                          genderResult: genderResult,
                        ),
                        SizedBox(height: lo.screenPadV),
                        if (genderResult != null) ...[
                          Semantics(
                            label: 'Gender: ${genderResult.gender}',
                            child: GenderResultCard(result: genderResult),
                          ),
                          SizedBox(height: spacing.m),
                        ],
                        if (breedResult != null)
                          Semantics(
                            label: 'Breed: ${breedResult.breed}',
                            child: BreedResultCard(result: breedResult),
                          ),
                        if (breedResult != null) ...[
                          SizedBox(height: spacing.m),
                          BreedInfoPreviewList(rawBreed: breedResult.breed),
                        ],
                        if (breedResult == null && genderResult == null)
                          const UnavailableCard(),
                        SizedBox(height: spacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    lo.screenPadH,
                    spacing.m,
                    lo.screenPadH,
                    spacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Button(
                          label: 'Cancel',
                          variant: ButtonVariant.outlined,
                          onPressed: onCancel,
                        ),
                      ),
                      SizedBox(width: spacing.m),
                      Expanded(
                        child: Button(
                          label: 'Save',
                          variant: ButtonVariant.primary,
                          onPressed: onSave,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: purpleHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.pink, brand.purple, brand.deepPurple],
                ),
              ),
              padding: EdgeInsets.fromLTRB(0, topPad + spacing.sm, 0, 0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: AppBackButton(onPressed: onCancel, color: onPrimary),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: spacing.m),
                    child: Label(
                      'Results',
                      variant: LabelVariant.title,
                      color: onPrimary,
                      size: 20,
                      weight: FontWeight.w700,
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
                padding: const EdgeInsets.all(3),
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
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({this.breedResult, this.genderResult});

  final BreedResult? breedResult;
  final GenderResult? genderResult;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final spacing = context.spacing;
    final gender = genderResult;
    final breed = breedResult;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        if (gender != null)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: brand.purple, width: 1.5),
            ),
            child: Icon(
              gender.gender.toLowerCase() == 'male'
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              color: brand.purple,
              size: 18,
            ),
          ),
        if (breed != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: context.radius.lg,
              border: Border.all(color: brand.purple, width: 1.5),
            ),
            child: Label(breed.breed, variant: LabelVariant.tag),
          ),
      ],
    );
  }
}
