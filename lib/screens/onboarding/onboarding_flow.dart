import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/onboarding/baseline_page.dart';
import 'package:zeno/screens/onboarding/onboarding_pages.dart';

// Pages: 0=Welcome, 1=Name, 2=ChooseCompanion, 3=Baseline, 4=Permissions,
// 5=MeetMochi
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _ctrl = PageController();
  int _page = 0;
  String _name = '';

  static const _pageCount = 6;

  void _next() {
    if (_page < _pageCount - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _saveBaseline(List<int> answers) async {
    await ref.read(appStateProvider.notifier).saveBaseline(
          BaselineResult(answers: answers, at: DateTime.now()),
        );
    if (mounted) _next();
  }

  Future<void> _finish() async {
    if (_name.trim().isNotEmpty) {
      ref.read(appStateProvider.notifier).updateUserName(_name.trim());
    }
    ref.read(appStateProvider.notifier).completeOnboarding();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: _ctrl,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [

            // 0 — Welcome
            WelcomePage(onNext: _next),
            // 1 — Name
            NameEntryPage(onNext: _next, onNameChanged: (v) => _name = v),
            // 2 — Choose companion (now vertical + popup)
            AvatarSelectionPage(
              onCompanionSelected: (_) {
                if (_page == 2) _next();
              },
            ),
            // 3 — Baseline questionnaire (starting score)
            BaselinePage(onComplete: _saveBaseline),
            // 4 — Permissions
            PermissionsPage(onNext: _next),
            // 5 — Meet Mochi (reveal animation + greeting)
            MeetMochiPage(name: _name, onFinish: _finish),
          ],
        ),
        // Progress dots
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: _OnboardingDots(current: _page, total: _pageCount),
        ),
        // Skip button (hidden on MeetMochi page)
        if (_page < _pageCount - 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: TextButton(
              onPressed: _finish,
              child: const Text('Skip',
                  style: TextStyle(color: Color(0xFF8A8899))),
            ),
          ),
      ]),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  final int current;
  final int total;
  const _OnboardingDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF7AB87A)
                : const Color(0xFF7AB87A).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
