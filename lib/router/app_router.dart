import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/router/scaffold_with_nav.dart';
import 'package:zeno/screens/onboarding/onboarding_flow.dart';
import 'package:zeno/screens/home/home_screen.dart';
import 'package:zeno/screens/quests/quests_screen.dart';
import 'package:zeno/screens/insights/insights_screen.dart';
import 'package:zeno/screens/scan/scan_screen.dart';
import 'package:zeno/screens/profile/profile_screen.dart';
import 'package:zeno/screens/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded =
      ref.watch(appStateProvider.select((s) => s.onboardingComplete));

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');
      if (!onboarded && !isSplash && !isOnboarding) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, state) => _fadePage(state, const OnboardingFlow()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (ctx, state, shell) =>
            _fadePage(state, ScaffoldWithNav(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/home',
                pageBuilder: (c, s) => _fadePage(s, const HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/quests',
                pageBuilder: (c, s) => _fadePage(s, const QuestsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/insights',
                pageBuilder: (c, s) => _fadePage(s, const InsightsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/scan',
                pageBuilder: (c, s) => _fadePage(s, const ScanScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                pageBuilder: (c, s) => _fadePage(s, const ProfileScreen())),
          ]),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (ctx, anim, _, c) =>
        FadeTransition(opacity: anim, child: c),
  );
}
