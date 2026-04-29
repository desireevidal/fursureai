import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_cat_name_dialog.dart';
import 'package:fursure/core/widgets/app_confirmation_dialog.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/core/widgets/unavailable_card.dart';
import 'package:fursure/features/breed_info/presentation/widgets/breed_info_preview_list.dart';
import 'package:fursure/features/prediction/data/breed_result.dart';
import 'package:fursure/features/prediction/data/gender_result.dart';
import 'package:fursure/features/prediction/presentation/widgets/breed_result_card.dart';
import 'package:fursure/features/prediction/presentation/widgets/gender_result_card.dart';
import '../data/prediction_record.dart';
import 'results_controller.dart';

class ResultDetailScreen extends ConsumerWidget {
  const ResultDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsControllerProvider);

    return resultsAsync.when(
      loading: () =>
          const AppPage(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => AppPage(
        title: '',
        child: Center(
          child: Label(
            'Failed to load result.',
            variant: LabelVariant.body,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (records) {
        final intId = int.tryParse(id);
        final record = intId != null
            ? records.where((r) => r.id == intId).firstOrNull
            : null;

        if (record == null) return const _NotFound();

        return _DetailView(
          record: record,
          onDelete: record.id == null
              ? null
              : () => ref
                    .read(resultsControllerProvider.notifier)
                    .deleteResult(record.id!),
          onRename: record.id == null
              ? null
              : (name) => ref
                    .read(resultsControllerProvider.notifier)
                    .updateResult(record.copyWith(catName: name)),
        );
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return AppPage(
      hasBottomNav: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.m),
            Label(
              'Result not found.',
              variant: LabelVariant.body,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.lg),
            Button(
              label: 'Back to History',
              onPressed: () => context.go('/history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({
    required this.record,
    this.onDelete,
    this.onRename,
  });

  final PredictionRecord record;
  final Future<void> Function()? onDelete;
  final Future<void> Function(String name)? onRename;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final topPad = MediaQuery.paddingOf(context).top;
    const headerBarHeight = 56.0;
    const circleSize = 140.0;
    final surfaceOverlap = context.radius.xl.topLeft.x;

    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final brand = context.brand;
    final spacing = context.spacing;
    final lo = context.layout;
    final contentMaxWidth = _adaptiveContentMaxWidth(viewportWidth);
    final expandedPurpleHeight = topPad + headerBarHeight + surfaceOverlap;
    final topSpacer = expandedPurpleHeight - surfaceOverlap;
    final metaTopPadding = lo.screenPadV;

    final hasBreed =
        widget.record.breed != null &&
        widget.record.breed!.isNotEmpty &&
        widget.record.breed != 'Unavailable';
    final hasGender =
        widget.record.gender != null &&
        widget.record.gender!.isNotEmpty &&
        widget.record.gender != 'Unavailable';

    final breedResult = hasBreed
        ? BreedResult(
            breed: widget.record.breed!,
            confidence: widget.record.breedConfidence ?? 0,
            secondaryBreed: widget.record.secondaryBreed,
            secondaryConfidence: widget.record.secondaryBreedConfidence,
          )
        : null;
    final genderResult = hasGender
        ? GenderResult(
            gender: widget.record.gender!,
            confidence: widget.record.genderConfidence ?? 0,
          )
        : null;

    return AppPage(
      hasBottomNav: true,
      horizontalPadding: false,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: expandedPurpleHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.pink, brand.purple, brand.deepPurple],
                ),
              ),
            ),
          ),
          Positioned(
            top: expandedPurpleHeight - surfaceOverlap,
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
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topSpacer),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          lo.screenPadH,
                          metaTopPadding,
                          lo.screenPadH,
                          0,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [brand.pink, brand.purple, brand.deepPurple],
                                ),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: widget.record.imagePath != null
                                    ? Image.file(
                                        File(widget.record.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, _) => ColoredBox(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 40,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                      ),
                              ),
                            ),
                            SizedBox(height: spacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Label(
                                    widget.record.catName?.isNotEmpty == true
                                        ? widget.record.catName!
                                        : 'Unknown Cat',
                                    variant: LabelVariant.h2,
                                    size: 28,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    uppercase: false,
                                  ),
                                ),
                                if (widget.onRename != null) ...[
                                  SizedBox(width: spacing.sm),
                                  GestureDetector(
                                    onTap: () => _editName(context),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: spacing.xs),
                            Label(
                              _timestamp(widget.record.timestamp),
                              variant: LabelVariant.caption,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              uppercase: false,
                            ),
                            SizedBox(height: spacing.m),
                            _TagsRow(record: widget.record),
                            SizedBox(height: lo.screenPadV),
                            if (genderResult != null) ...[
                              Semantics(
                                label: 'Gender: ${genderResult.gender}',
                                child: GenderResultCard(result: genderResult),
                              ),
                              SizedBox(height: spacing.m),
                            ],
                            if (breedResult != null) ...[
                              Semantics(
                                label: 'Breed: ${breedResult.breed}',
                                child: BreedResultCard(result: breedResult),
                              ),
                              SizedBox(height: spacing.m),
                              BreedInfoPreviewList(
                                rawBreed: breedResult.shouldShowSecondary
                                    ? '${breedResult.breed}, ${breedResult.secondaryBreed}'
                                    : breedResult.breed,
                              ),
                            ],
                            if (breedResult == null && genderResult == null)
                              const UnavailableCard(),
                            SizedBox(height: lo.navBarTotalHeight + spacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + headerBarHeight,
            child: Padding(
              padding: EdgeInsets.only(top: topPad + spacing.xs),
              child: SizedBox(
                height: headerBarHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(
                        onPressed: () => context.pop(),
                        color: onPrimary,
                      ),
                    ),
                    Label(
                      'Pawfile',
                      variant: LabelVariant.title,
                      color: onPrimary,
                      uppercase: false,
                    ),
                    if (widget.onDelete != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            spacing.m,
                            spacing.sm,
                            lo.screenPadH,
                            spacing.sm,
                          ),
                          child: GestureDetector(
                            onTap: () => _confirmDelete(context),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: onPrimary,
                              size: lo.iconSizeM,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showAppConfirmationDialog(
      context,
      title: 'Delete Pawfile',
      message: 'This entry will be removed from My Clawlection.',
      confirmLabel: 'Delete',
    );

    if (shouldDelete == true && widget.onDelete != null) {
      await widget.onDelete!.call();
      if (context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> _editName(BuildContext context) async {
    if (widget.onRename == null) return;

    final updatedName = await showAppCatNameDialog(
      context,
      initialName: widget.record.catName ?? '',
    );

    if (updatedName != null && updatedName.isNotEmpty) {
      await widget.onRename!(updatedName);
    }
  }

  String _timestamp(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Analysed just now';
    if (d.inHours < 1) return 'Analysed ${d.inMinutes}m ago';
    if (d.inDays < 1) return 'Analysed ${d.inHours}h ago';
    return 'Analysed on ${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.record});

  final PredictionRecord record;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final spacing = context.spacing;

    final hasBreed =
        record.breed != null &&
        record.breed!.isNotEmpty &&
        record.breed != 'Unavailable';
    final hasGender =
        record.gender != null &&
        record.gender!.isNotEmpty &&
        record.gender != 'Unavailable';
    final showSecondaryBreed =
        hasBreed &&
        record.secondaryBreed != null &&
        record.secondaryBreed!.isNotEmpty &&
        record.secondaryBreedConfidence != null &&
        ((record.secondaryBreedConfidence! >= 0.10) ||
            ((record.breedConfidence ?? 0) - record.secondaryBreedConfidence!) <=
                0.15);

    if (!hasBreed && !hasGender) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        if (hasGender)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: brand.purple, width: 1.5),
            ),
            child: Icon(
              record.gender!.toLowerCase() == 'male'
                  ? Icons.male_rounded
                  : Icons.female_rounded,
              color: brand.purple,
              size: 18,
            ),
          ),
        if (hasBreed)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: context.radius.lg,
              border: Border.all(color: brand.purple, width: 1.5),
            ),
            child: Label(record.breed!, variant: LabelVariant.tag),
          ),
        if (showSecondaryBreed)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: context.radius.lg,
              border: Border.all(color: brand.purple, width: 1.5),
            ),
            child: Label(record.secondaryBreed!, variant: LabelVariant.tag),
          ),
      ],
    );
  }
}

double _adaptiveContentMaxWidth(double width) {
  if (width >= 1100) return 760;
  if (width >= 800) return 680;
  return width;
}
