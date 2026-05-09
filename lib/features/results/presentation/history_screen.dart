import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_confirmation_dialog.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/label.dart';
import '../data/prediction_record.dart';
import 'results_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const String _allBreedsValue = '__all_breeds__';
  static const String _allGendersValue = '__all_genders__';

  String _searchQuery = '';
  String? _selectedBreed;
  String? _selectedGender;
  bool _showSearch = false;
  bool _sortMostRecent = true;
  bool _showGridTopFade = false;
  final Set<int> _selectedIds = <int>{};
  late final TextEditingController _searchController;
  late final ScrollController _historyScrollController;

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _historyScrollController = ScrollController()
      ..addListener(_handleHistoryScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historyScrollController
      ..removeListener(_handleHistoryScroll)
      ..dispose();
    super.dispose();
  }

  void _handleHistoryScroll() {
    final shouldShow =
        _historyScrollController.hasClients &&
        _historyScrollController.offset > 24;
    if (shouldShow != _showGridTopFade && mounted) {
      setState(() => _showGridTopFade = shouldShow);
    }
  }

  bool get _shouldShowGridTopFade =>
      _showGridTopFade &&
      _historyScrollController.hasClients &&
      _historyScrollController.offset > 24;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final resultsAsync = ref.watch(resultsControllerProvider);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final contentMaxWidth = _adaptiveContentMaxWidth(viewportWidth);
    final headerGradient = _collectionHeaderGradient(context.brand);
    final radius = context.radius.xxl;

    return AppPage(
      hasBottomNav: true,
      horizontalPadding: false,
      backgroundColor: context.brand.purple,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: headerGradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CollectionHeader(
              maxContentWidth: contentMaxWidth,
              isSelectionMode: _isSelectionMode,
              selectedCount: _selectedIds.length,
              showSearch: _showSearch,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              onSearchToggle: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
              onExitSelection: _clearSelection,
              onDeleteSelected: _deleteSelected,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: radius.topLeft,
                    topRight: radius.topRight,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: viewportWidth >= 720
                              ? context.spacing.lg
                              : context.spacing.m,
                        ),
                        child: resultsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Label(
                            'Failed to load history.',
                            variant: LabelVariant.body,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        data: (records) {
                          if (records.isEmpty) return const _EmptyState();

                          final breedOptions = _collectValues(
                            records.map((record) => record.breed),
                          );
                          final genderOptions = _collectValues(
                            records.map((record) => record.gender),
                          );
                          final filteredRecords = _applyFilters(records);

                          return Column(
                            children: [
                              _FilterRow(
                                breedOptions: breedOptions,
                                genderOptions: genderOptions,
                                selectedBreed: _selectedBreed,
                                selectedGender: _selectedGender,
                                allBreedsValue: _allBreedsValue,
                                allGendersValue: _allGendersValue,
                                sortMostRecent: _sortMostRecent,
                                onSortChanged: (value) =>
                                    setState(() => _sortMostRecent = value),
                                onBreedChanged: (value) => setState(
                                  () => _selectedBreed =
                                      value == _allBreedsValue ? null : value,
                                ),
                                onGenderChanged: (value) => setState(
                                  () => _selectedGender =
                                      value == _allGendersValue ? null : value,
                                ),
                              ),
                              if (_isSelectionMode)
                                _SelectionActionBar(
                                  selectedCount: _selectedIds.length,
                                  onSelectAll: () =>
                                      _selectAllVisible(filteredRecords),
                                  onClearSelection: _clearSelection,
                                ),
                              Expanded(
                                child: filteredRecords.isEmpty
                                    ? const _NoMatchesState()
                                    : Stack(
                                        children: [
                                          _HistoryGrid(
                                            controller:
                                                _historyScrollController,
                                            records: filteredRecords,
                                            isSelectionMode: _isSelectionMode,
                                            selectedIds: _selectedIds,
                                            onToggleSelection:
                                                _toggleSelection,
                                            onStartSelection: _startSelection,
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            height: 52,
                                            child: IgnorePointer(
                                              child: AnimatedOpacity(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                curve: Curves.easeOut,
                                                opacity:
                                                    _shouldShowGridTopFade
                                                        ? 1
                                                        : 0,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                        surfaceColor,
                                                        surfaceColor
                                                            .withValues(
                                                          alpha: 0.76,
                                                        ),
                                                        surfaceColor
                                                            .withValues(
                                                          alpha: 0.0,
                                                        ),
                                                      ],
                                                      stops: const [
                                                        0.0,
                                                        0.42,
                                                        1.0,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _collectValues(Iterable<String?> values) {
    final seen = <String>{};
    final results = <String>[];

    for (final value in values) {
      if (value == null || value.isEmpty || value == 'Unavailable') continue;
      if (seen.add(value)) results.add(value);
    }

    results.sort();
    return results;
  }

  List<PredictionRecord> _applyFilters(List<PredictionRecord> records) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = records.where((record) {
      final matchesBreed =
          _selectedBreed == null || record.breed == _selectedBreed;
      final matchesGender =
          _selectedGender == null || record.gender == _selectedGender;

      final matchesSearch =
          query.isEmpty ||
          (record.catName?.toLowerCase().contains(query) ?? false) ||
          (record.breed?.toLowerCase().contains(query) ?? false) ||
          (record.gender?.toLowerCase().contains(query) ?? false);

      return matchesBreed && matchesGender && matchesSearch;
    }).toList();

    filtered.sort((a, b) => _sortMostRecent
        ? b.timestamp.compareTo(a.timestamp)
        : a.timestamp.compareTo(b.timestamp));

    return filtered;
  }

  LinearGradient _collectionHeaderGradient(BrandColors brand) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        brand.pink,
        Color.lerp(brand.pink, brand.purple, 0.45)!,
        brand.purple,
      ],
      stops: const [0.0, 0.42, 1.0],
    );
  }

  void _startSelection(PredictionRecord record) {
    final id = record.id;
    if (id == null) return;

    setState(() {
      _selectedIds
        ..clear()
        ..add(id);
      _showSearch = false;
    });
  }

  void _toggleSelection(PredictionRecord record) {
    final id = record.id;
    if (id == null) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _selectAllVisible(List<PredictionRecord> records) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(records.map((record) => record.id).whereType<int>());
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final shouldDelete = await showAppConfirmationDialog(
      context,
      title: 'Delete Pawfile?',
      message: count == 1
          ? 'This entry will be removed from My Clawlection.'
          : '$count entries will be removed from My Clawlection.',
      confirmLabel: 'Delete',
    );

    if (shouldDelete != true) return;

    final ids = _selectedIds.toList(growable: false);
    for (final id in ids) {
      await ref.read(resultsControllerProvider.notifier).deleteResult(id);
    }

    if (mounted) {
      setState(() => _selectedIds.clear());
    }
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.record,
    required this.isSelectionMode,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  final PredictionRecord record;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  bool _isAvailable(String? v) => v != null && v != 'Unavailable';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final bool hasBreed = _isAvailable(record.breed);
    final bool hasGender = _isAvailable(record.gender);
    final String title = _resolveTitle(hasBreed, hasGender);
    final String genderLabel = hasGender ? record.gender! : 'Unknown';
    final String breedLabel = hasBreed ? record.breed! : 'Unavailable';
    final BorderRadius cardRadius = context.radius.m;

    return Semantics(
      button: true,
      label: '$title, $breedLabel, $genderLabel',
      selected: isSelected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: isSelected
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surface,
          borderRadius: cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: cardRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: cardRadius,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _HistoryCardImage(
                          imagePath: record.imagePath,
                          hasBreed: hasBreed,
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            spacing.m,
                            spacing.xs,
                            spacing.m,
                            spacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label(
                                title,
                                variant: LabelVariant.title,
                                size: 18,
                                color: theme.colorScheme.primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                uppercase: false,
                              ),
                              SizedBox(height: spacing.xs),
                              _MetaRow(
                                icon: _genderIcon(genderLabel),
                                text: genderLabel,
                              ),
                              SizedBox(height: spacing.xs),
                              _MetaRow(icon: Icons.pets_outlined, text: breedLabel),
                              SizedBox(height: spacing.sm),
                              Label(
                                _timeAgo(record.timestamp),
                                variant: LabelVariant.caption,
                                size: 11,
                                color: theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.72,
                                ),
                                uppercase: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSelectionMode)
                    Positioned(
                      top: spacing.sm,
                      right: spacing.sm,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.black.withValues(alpha: 0.28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: Colors.white,
                          size: 16,
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

  String _resolveTitle(bool hasBreed, bool hasGender) {
    if (_isAvailable(record.catName)) return record.catName!;
    if (hasBreed) return record.breed!;
    if (hasGender) return record.gender!;
    return 'Analysis unavailable';
  }

  IconData _genderIcon(String genderLabel) {
    switch (genderLabel.toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _HistoryCardImage extends StatelessWidget {
  const _HistoryCardImage({required this.imagePath, required this.hasBreed});

  final String? imagePath;
  final bool hasBreed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lo = context.layout;
    final BorderRadius imageRadius = BorderRadius.only(
      topLeft: context.radius.m.topLeft,
      topRight: context.radius.m.topRight,
    );

    final fallback = Container(
      decoration: BoxDecoration(
        borderRadius: imageRadius,
        color: theme.colorScheme.secondaryContainer,
      ),
      child: Icon(
        hasBreed ? Icons.pets : Icons.mic_rounded,
        size: lo.iconContainerL,
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );

    if (imagePath == null) return fallback;

    return ClipRRect(
      borderRadius: imageRadius,
      child: Image.file(
        File(imagePath!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, _) => fallback,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lo = context.layout;
    return Row(
      children: [
        Icon(
          icon,
          size: lo.iconSizeS,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Label(
            text,
            variant: LabelVariant.subtitle,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            uppercase: false,
          ),
        ),
      ],
    );
  }
}

class _HistoryGrid extends StatelessWidget {
  const _HistoryGrid({
    required this.controller,
    required this.records,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onStartSelection,
  });

  final ScrollController controller;
  final List<PredictionRecord> records;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final ValueChanged<PredictionRecord> onToggleSelection;
  final ValueChanged<PredictionRecord> onStartSelection;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;
    final screenSize = MediaQuery.sizeOf(context);
    final bottomClearance = MediaQuery.paddingOf(context).bottom + spacing.lg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = screenSize.width > screenSize.height;
        final isTallTabletPortrait = !isLandscape &&
            screenSize.height >= 1000 &&
            constraints.maxWidth >= 560;

        late final int columns;
        if (constraints.maxWidth >= 1200) {
          columns = isLandscape ? 5 : 4;
        } else if (constraints.maxWidth >= 900) {
          columns = isLandscape ? 4 : 3;
        } else if (constraints.maxWidth >= 760 || isTallTabletPortrait) {
          columns = 3;
        } else {
          columns = 2;
        }

        late final double childAspectRatio;
        if (isLandscape) {
          if (constraints.maxWidth >= 1200) {
            childAspectRatio = 1.18;
          } else if (constraints.maxWidth >= 900) {
            childAspectRatio = 1.08;
          } else if (constraints.maxWidth >= 760) {
            childAspectRatio = 0.98;
          } else {
            childAspectRatio = 0.92;
          }
        } else if (isTallTabletPortrait && constraints.maxWidth < 760) {
          childAspectRatio = 0.82;
        } else if (constraints.maxWidth >= 1200) {
          childAspectRatio = 0.84;
        } else if (constraints.maxWidth >= 760) {
          childAspectRatio = 0.94;
        } else {
          childAspectRatio = 0.83;
        }

        return GridView.builder(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            lo.screenPadH,
            spacing.sm,
            lo.screenPadH,
            bottomClearance,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing.sm,
            mainAxisSpacing: spacing.sm,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final PredictionRecord record = records[index];
            return HistoryTile(
              record: record,
              isSelectionMode: isSelectionMode,
              isSelected:
                  record.id != null && selectedIds.contains(record.id),
              onTap: record.id == null
                  ? null
                  : () {
                      if (isSelectionMode) {
                        onToggleSelection(record);
                      } else {
                        context.go('/history/${record.id}');
                      }
                    },
              onLongPress: record.id == null
                  ? null
                  : () {
                      if (isSelectionMode) {
                        onToggleSelection(record);
                      } else {
                        onStartSelection(record);
                      }
                    },
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.xxl,
        0,
        context.spacing.xxl,
        lo.navBarTotalHeight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: lo.emptyStateIconSize,
            height: lo.emptyStateIconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.63),
            ),
          ),
          SizedBox(height: spacing.lg),
          const Label(
            'Your Clawlection is empty.',
            variant: LabelVariant.title,
            size: 22,
          ),
          SizedBox(height: spacing.sm),
          Label(
            'Click the camera button to start your Clawlection!',
            variant: LabelVariant.body,
            align: TextAlign.center,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.maxContentWidth,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchToggle,
    required this.onExitSelection,
    required this.onDeleteSelected,
  });

  final double maxContentWidth;
  final bool isSelectionMode;
  final int selectedCount;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchToggle;
  final VoidCallback onExitSelection;
  final Future<void> Function() onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final spacing = context.spacing;
    final topPad = MediaQuery.paddingOf(context).top;
    final lo = context.layout;
    final bottomInset = context.radius.xl.topLeft.x;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        0,
        topPad + spacing.sm,
        0,
        (showSearch ? spacing.xs : spacing.sm) + (bottomInset * 0.38),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            brand.pink,
            Color.lerp(brand.pink, brand.purple, 0.45)!,
            brand.purple,
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                  children: [
                    SizedBox(
                      width: lo.screenPadH + lo.iconContainerS,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: lo.screenPadH, top: spacing.xs),
                          child: isSelectionMode
                              ? IconButton(
                                  onPressed: onExitSelection,
                                  tooltip: 'Close selection',
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: lo.iconSizeM,
                                  ),
                                )
                              : AppBackButton(
                                  onPressed: () => context.go('/home'),
                                  color: Colors.white,
                                  padded: false,
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: spacing.sm),
                        child: Label(
                          isSelectionMode
                              ? '$selectedCount selected'
                              : 'My Clawlection',
                          variant: LabelVariant.title,
                          size: 22,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          align: TextAlign.center,
                          uppercase: false,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: lo.screenPadH + lo.iconContainerS,
                      child: Padding(
                        padding: EdgeInsets.only(top: spacing.xs, right: spacing.sm),
                        child: isSelectionMode
                            ? IconButton(
                                onPressed: () => onDeleteSelected(),
                                tooltip: 'Delete selected',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: lo.iconSizeM,
                                ),
                              )
                            : IconButton(
                                onPressed: onSearchToggle,
                                tooltip: 'Search entries',
                                icon: Icon(
                                  showSearch
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                  color: Colors.white,
                                  size: lo.iconSizeM,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                if (!isSelectionMode && showSearch) ...[
                  SizedBox(height: spacing.sm),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: lo.screenPadH),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name, breed, or gender',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.14),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing.m,
                          vertical: spacing.sm,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: context.radius.xxl,
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: context.radius.xxl,
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

double _adaptiveContentMaxWidth(double width) {
  if (width >= 1200) return width - 96;
  if (width >= 900) return width - 72;
  if (width >= 720) return width - 40;
  return width;
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.breedOptions,
    required this.genderOptions,
    required this.selectedBreed,
    required this.selectedGender,
    required this.allBreedsValue,
    required this.allGendersValue,
    required this.sortMostRecent,
    required this.onSortChanged,
    required this.onBreedChanged,
    required this.onGenderChanged,
  });

  final List<String> breedOptions;
  final List<String> genderOptions;
  final String? selectedBreed;
  final String? selectedGender;
  final String allBreedsValue;
  final String allGendersValue;
  final bool sortMostRecent;
  final ValueChanged<bool> onSortChanged;
  final ValueChanged<String> onBreedChanged;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final verticalPadding = viewportWidth >= 720 ? spacing.sm : 4.0;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
          lo.screenPadH,
          verticalPadding,
          lo.screenPadH,
          verticalPadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth - (lo.screenPadH * 2)),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CollectionChipButton<bool>(
                  label: sortMostRecent ? 'Most Recent' : 'Oldest',
                  icon: Icons.access_time_rounded,
                  highlighted: true,
                  value: sortMostRecent,
                  options: const [
                    PopupMenuItem<bool>(value: true, child: Text('Most Recent')),
                    PopupMenuItem<bool>(value: false, child: Text('Oldest')),
                  ],
                  onSelected: onSortChanged,
                ),
                _CollectionChipButton<String>(
                  label: selectedBreed ?? 'Breed',
                  value: selectedBreed ?? allBreedsValue,
                  icon: selectedBreed != null ? Icons.pets_rounded : null,
                  options: [
                    PopupMenuItem<String>(
                      value: allBreedsValue,
                      child: const Text('All breeds'),
                    ),
                    ...breedOptions.map(
                      (breed) => PopupMenuItem<String>(value: breed, child: Text(breed)),
                    ),
                  ],
                  onSelected: onBreedChanged,
                ),
                _CollectionChipButton<String>(
                  label: selectedGender ?? 'Gender',
                  value: selectedGender ?? allGendersValue,
                  icon: _selectedGenderIcon(selectedGender),
                  options: [
                    PopupMenuItem<String>(
                      value: allGendersValue,
                      child: const Text('All genders'),
                    ),
                    ...genderOptions.map(
                      (gender) => PopupMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      ),
                    ),
                  ],
                  onSelected: onGenderChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData? _selectedGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return null;
    }
  }
}

class _CollectionChipButton<T> extends StatelessWidget {
  const _CollectionChipButton({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final T value;
  final List<PopupMenuEntry<T>> options;
  final ValueChanged<T> onSelected;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final brand = context.brand;
    final theme = Theme.of(context);

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => options,
      child: Container(
        margin: EdgeInsets.only(right: spacing.sm),
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: spacing.m),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted
              ? brand.purple.withValues(alpha: 0.14)
              : theme.colorScheme.surface,
          borderRadius: context.radius.xxl,
          border: Border.all(
            color: highlighted
                ? brand.purple.withValues(alpha: 0.38)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: highlighted ? brand.purple : theme.colorScheme.primary,
              ),
              SizedBox(width: spacing.xs),
            ],
            Label(
              label,
              variant: LabelVariant.caption,
              size: 11,
              weight: FontWeight.w700,
              color: highlighted ? brand.purple : theme.colorScheme.primary,
              uppercase: true,
            ),
            SizedBox(width: spacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: highlighted ? brand.purple : theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        lo.screenPadH,
        spacing.sm,
        lo.screenPadH,
        0,
      ),
      child: Row(
        children: [
          _ActionIconChip(
            icon: Icons.select_all,
            tooltip: 'Select all visible',
            onTap: onSelectAll,
          ),
          SizedBox(width: spacing.sm),
          _ActionIconChip(
            icon: Icons.remove_done,
            tooltip: 'Unselect all',
            onTap: onClearSelection,
          ),
          const Spacer(),
          Label(
            '$selectedCount selected',
            variant: LabelVariant.caption,
            color: theme.colorScheme.onSurfaceVariant,
            uppercase: false,
          ),
        ],
      ),
    );
  }
}

class _ActionIconChip extends StatelessWidget {
  const _ActionIconChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: context.radius.xxl,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.radius.xxl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.sm,
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            SizedBox(height: spacing.m),
            const Label(
              'No matching pawfiles',
              variant: LabelVariant.title,
              size: 20,
              uppercase: false,
            ),
            SizedBox(height: spacing.xs),
            Label(
              'Try a different search term or reset your filters.',
              variant: LabelVariant.body,
              align: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
