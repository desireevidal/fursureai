import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fursure/features/home/presentation/home_screen.dart';
import 'package:fursure/features/onboarding/presentation/permissions_screen.dart';
import 'package:fursure/features/onboarding/presentation/welcome_screen.dart';
import 'package:fursure/features/prediction/presentation/scan_screen.dart';
import 'package:fursure/features/results/presentation/history_screen.dart';
import 'package:fursure/features/results/presentation/result_detail_screen.dart';
import 'package:fursure/features/settings/presentation/settings_screen.dart';
import 'package:fursure/features/startup/presentation/startup_screen.dart';
import '../widgets/animated_branch_container.dart';
import '../widgets/app_shell.dart';
import '../widgets/fab_reveal_transition.dart';

GoRouter createAppRouter() {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/startup',
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final FabRevealTransitionData? transitionData =
              state.extra is FabRevealTransitionData
              ? state.extra as FabRevealTransitionData
              : null;

          if (transitionData == null) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 500),
              reverseTransitionDuration: const Duration(milliseconds: 340),
              child: const ScanScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final Animation<double> curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubicEmphasized,
                      reverseCurve: Curves.easeInOutCubic,
                    );
                    final Animation<double> scaleAnimation = Tween<double>(
                      begin: 0.92,
                      end: 1.0,
                    ).animate(curvedAnimation);
                    final Animation<Offset> slideAnimation = Tween<Offset>(
                      begin: const Offset(0.0, 0.08),
                      end: Offset.zero,
                    ).animate(curvedAnimation);

                    return FadeTransition(
                      opacity: curvedAnimation,
                      child: SlideTransition(
                        position: slideAnimation,
                        child: ScaleTransition(
                          scale: scaleAnimation,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      ),
                    );
                  },
            );
          }

          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 560),
            reverseTransitionDuration: const Duration(milliseconds: 380),
            child: const ScanScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FabRevealTransition(
                      animation: animation,
                      transitionData: transitionData,
                      child: child,
                    ),
          );
        },
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        ResultDetailScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
