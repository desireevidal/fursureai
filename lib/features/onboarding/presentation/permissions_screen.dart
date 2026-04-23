import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/providers/app_providers.dart';
import 'widgets/permission_item_tile.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  Future<void> _allow(BuildContext context, WidgetRef ref) async {
    await [Permission.camera, Permission.microphone].request();

    await ref.read(onboardingServiceProvider).markSeen();
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = context.brand;

    return Scaffold(
      backgroundColor: brand.purple,
      body: Column(
        children: [
          Expanded(
            flex: 32,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/permissions_illustration.svg',
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 68,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: isDark ? 0.15 : 0.10,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 29),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      const Label('Permissions', variant: LabelVariant.h2),
                      SizedBox(height: context.spacing.m),

                      const Label(
                        "To identify your cat's breed and gender accurately, "
                        'FurSure AI requires access to the following:',
                        variant: LabelVariant.body,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      const PermissionItemTile(
                        icon: Icons.camera_alt_outlined,
                        label: 'Allow to access camera',
                      ),
                      const SizedBox(height: 14),
                      const PermissionItemTile(
                        icon: Icons.mic_outlined,
                        label: 'Allow to access microphone',
                      ),

                      const Spacer(),

                      Button(
                        label: 'Allow',
                        onPressed: () => _allow(context, ref),
                        backgroundColor: brand.pink,
                      ),
                      SizedBox(height: context.spacing.xl),
                    ],
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
