import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fursure/core/constants/app_constants.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/branded_page.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/providers/app_providers.dart';
import 'package:fursure/features/results/presentation/results_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _micStatus = PermissionStatus.denied;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    setState(() {
      _cameraStatus = camera;
      _micStatus = mic;
    });
  }

  Future<void> _doExport() async {
    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => const _ExportChoiceSheet(),
    );
    if (choice == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final zipPath = await service.buildBackupZip();

      if (!mounted) return;

      if (choice == _ExportChoice.share) {
        await Share.shareXFiles(
          [XFile(zipPath, mimeType: 'application/zip')],
          subject: 'FurSure backup',
        );
      } else {
        final savedPath = await service.saveToDevice(zipPath);
        if (mounted && savedPath != null) {
          _showAppSnackBar(
            'Backup saved successfully',
            icon: Icons.check_circle_outline_rounded,
            variant: _SnackBarVariant.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showAppSnackBar(
          'Export failed. Please try again.',
          icon: Icons.error_outline_rounded,
          variant: _SnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _doImport() async {
    setState(() => _isImporting = true);
    try {
      final result = await ref.read(backupServiceProvider).import();
      if (result == null) return;
      if (result.restoredTheme != null) {
        ref
            .read(themeModeControllerProvider.notifier)
            .updateThemeMode(result.restoredTheme!);
      }
      ref.invalidate(resultsControllerProvider);
      if (mounted) {
        final skippedNote = result.skipped > 0
            ? ' · ${result.skipped} already existed'
            : '';
        _showAppSnackBar(
          'Imported ${result.imported} record${result.imported == 1 ? '' : 's'}$skippedNote',
          icon: Icons.check_circle_outline_rounded,
          variant: _SnackBarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showAppSnackBar(
          'Import failed. Please try again.',
          icon: Icons.error_outline_rounded,
          variant: _SnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showAppSnackBar(
    String message, {
    required IconData icon,
    required _SnackBarVariant variant,
  }) {
    final brand = context.brand;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    switch (variant) {
      case _SnackBarVariant.success:
        bg = isDark
            ? const Color(0xFF1E3A2F)
            : const Color(0xFF1A6640);
        fg = const Color(0xFFDCF5E8);
      case _SnackBarVariant.error:
        bg = isDark
            ? Color.lerp(brand.softRed, Colors.black, 0.55)!
            : brand.softRed;
        fg = Colors.white;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: context.radius.m),
          margin: EdgeInsets.symmetric(
            horizontal: context.spacing.m,
            vertical: context.spacing.sm,
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: fg, size: 18),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Label(
                  message,
                  variant: LabelVariant.caption,
                  size: 13,
                  color: fg,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final lo = context.layout;
    final selectedThemeMode = ref.watch(themeModeControllerProvider);

    return BrandedPage(
      title: 'Settings',
      hasBottomNav: true,
      horizontalPadding: false,
      showSurfaceCap: true,
      useGradientHeader: true,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: lo.screenPadH),
        children: [
          const _SectionHeader(title: 'Appearance', topSpacing: 8),
          _SettingsCard(
            children: [
              _ThemeModeTile(
                selectedThemeMode: selectedThemeMode,
                onThemeModeChanged: (themeMode) {
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .updateThemeMode(themeMode);
                },
              ),
            ],
          ),
          const _SectionHeader(title: 'App Permissions'),
          _SettingsCard(
            children: [
              _PermissionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                status: _cameraStatus,
              ),
              _PermissionTile(
                icon: Icons.mic_none_rounded,
                label: 'Microphone',
                status: _micStatus,
              ),
            ],
          ),
          const _SectionHeader(title: 'Backup and restore'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: 'Create backup',
                onTap: _isExporting ? null : _doExport,
                trailing: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              _SettingsTile(
                icon: Icons.restore_rounded,
                title: 'Restore backup',
                onTap: _isImporting ? null : _doImport,
                trailing: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Center(
            child: Consumer(
              builder: (context, ref, _) {
                final versionAsync = ref.watch(appVersionProvider);
                final theme = Theme.of(context);
                return Label(
                  versionAsync.when(
                    data: (v) => v,
                    loading: () => 'Version ...',
                    error: (_, _) => 'Version ?.?',
                  ),
                  variant: LabelVariant.caption,
                  size: 11,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;

    return _SettingsTile(
      icon: Icons.palette_outlined,
      title: 'Theme',
      onTap: () async {
        final themeMode = await showDialog<ThemeMode>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Label('Appearance', variant: LabelVariant.title),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: RadioGroup<ThemeMode>(
              groupValue: selectedThemeMode,
              onChanged: (v) => Navigator.of(context).pop(v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (mode, icon, label) in [
                    (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
                    (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
                    (
                      ThemeMode.system,
                      Icons.brightness_auto_outlined,
                      'System',
                    ),
                  ])
                    RadioListTile<ThemeMode>(
                      value: mode,
                      secondary: Icon(icon, size: lo.iconSizeS),
                      title: Label(label, variant: LabelVariant.body),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                ],
              ),
            ),
          ),
        );

        if (themeMode != null) {
          onThemeModeChanged(themeMode);
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Label(
            _themeModeLabel(selectedThemeMode),
            variant: LabelVariant.caption,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: spacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            size: lo.iconSizeS,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.topSpacing,
  });

  final String title;
  final double? topSpacing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(
        top: topSpacing ?? spacing.lg,
        bottom: spacing.sm,
      ),
      child: Label(title, variant: LabelVariant.title, weight: FontWeight.w700),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: context.radius.m),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(children: _buildChildren(theme)),
    );
  }

  List<Widget> _buildChildren(ThemeData theme) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            indent: 0,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
    }
    return result;
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;

    return InkWell(
      onTap: onTap,
      borderRadius: context.radius.m,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.m,
          vertical: spacing.m,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: lo.iconSizeS,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: spacing.m),
            Expanded(child: Label(title, variant: LabelVariant.body)),
            ?trailing,
            if (trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                size: lo.iconSizeS,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

enum _ExportChoice { saveToDevice, share }

enum _SnackBarVariant { success, error }

class _ExportChoiceSheet extends StatelessWidget {
  const _ExportChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final brand = context.brand;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.m, spacing.sm, spacing.m, spacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
            // Header
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    'Export backup',
                    variant: LabelVariant.title,
                    weight: FontWeight.w700,
                  ),
                  SizedBox(height: spacing.xs),
                  Label(
                    'Choose how to save your backup file',
                    variant: LabelVariant.caption,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.m),
            // Option cards
            _ExportOptionTile(
              icon: Icons.save_alt_outlined,
              gradient: brand.gradient,
              title: 'Save to device',
              subtitle: 'Download to your local storage',
              onTap: () => Navigator.of(context).pop(_ExportChoice.saveToDevice),
            ),
            SizedBox(height: spacing.sm),
            _ExportOptionTile(
              icon: Icons.share_outlined,
              gradient: [brand.purple, brand.deepPurple],
              title: 'Share',
              subtitle: 'Send via AirDrop, Drive, Messages…',
              onTap: () => Navigator.of(context).pop(_ExportChoice.share),
            ),
            SizedBox(height: spacing.m),
            // Cancel
            SizedBox(
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
                child: const Label('Cancel', variant: LabelVariant.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: context.radius.m,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radius.m,
        child: Container(
          padding: EdgeInsets.all(spacing.m),
          decoration: BoxDecoration(
            borderRadius: context.radius.m,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: context.radius.sm,
                ),
                child: Icon(icon, color: Colors.white, size: lo.iconSizeS),
              ),
              SizedBox(width: spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(title, variant: LabelVariant.body, weight: FontWeight.w600),
                    SizedBox(height: 2),
                    Label(
                      subtitle,
                      variant: LabelVariant.caption,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: lo.iconSizeS,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final lo = context.layout;
    final granted = status.isGranted;

    return _SettingsTile(
      icon: icon,
      title: label,
      onTap: granted ? null : () => openAppSettings(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: context.radius.sm,
              color: granted
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.errorContainer,
            ),
            child: Label(
              granted ? 'Allowed' : 'Denied',
              variant: LabelVariant.caption,
              size: 11,
              weight: FontWeight.w600,
              color: granted
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onErrorContainer,
            ),
          ),
          SizedBox(width: spacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            size: lo.iconSizeS,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
