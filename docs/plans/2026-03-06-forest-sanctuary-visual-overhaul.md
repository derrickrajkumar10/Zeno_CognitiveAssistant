# Forest Sanctuary Visual Overhaul — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform ZENO into a forest-sanctuary aesthetic with a cinematic Mochi introduction, staggered quest animations, smooth CogniPulse transitions, hero animations, and a polished onboarding flow.

**Architecture:** Update the central `AppTheme` first (everything derives from it), then build upward — leaf particle primitive, enhanced MochiPainter, individual screen animations, then the cinematic intro sequence last. Each task is independently testable/runnable with `flutter run`.

**Tech Stack:** Flutter (Dart), `flutter_animate` (already installed), `AnimationController` + `TweenAnimationBuilder`, `CustomPainter`, Riverpod, go_router.

**Design doc:** `docs/plans/2026-03-05-forest-sanctuary-visual-overhaul-design.md`

---

## Task 1: Forest Sanctuary Palette — `app_theme.dart`

**Files:**
- Modify: `lib/theme/app_theme.dart`

Replace all colour constants and ambient gradients with the forest sanctuary palette. This is the foundation — everything else inherits from here.

**Step 1: Apply new colour constants**

Replace the entire colour block at the top of `AppTheme` (lines 6–18) with:

```dart
static const Color backgroundDeep   = Color(0xFFF2F5EF);
static const Color backgroundMid    = Color(0xFFEFF3EC);
static const Color cardSurface      = Color(0xFFFAFCF8);
static const Color cardSurfaceLight = Color(0xFFF4F7F2);
static const Color primaryAccent    = Color(0xFF7AB87A); // sage green
static const Color warmAccent       = Color(0xFFD4A574); // warm wood amber
static const Color textPrimary      = Color(0xFF2A3828); // deep forest
static const Color textSecondary    = Color(0xFF7A8C80); // muted sage
static const Color successMint      = Color(0xFF5BBF8A);
static const Color warningAmber     = Color(0xFFE8A84A);
static const Color selectedTint     = Color(0xFFEDF5ED);
static const Color selectedBorder   = Color(0xFF5BBF8A);
static const Color buttonDark       = Color(0xFF2A3828);
```

**Step 2: Replace Mochi mood colours**

```dart
static const Color mochiBalanced    = Color(0xFF7AB87A); // sage green
static const Color mochiThriving    = Color(0xFFD4A574); // warm wood amber
static const Color mochiDrifting    = Color(0xFF8BA89B); // grey-green mist
static const Color mochiStruggling  = Color(0xFF7A8B84); // desaturated green
```

**Step 3: Replace `ambientGradient` method**

```dart
static List<Color> ambientGradient(int score) {
  if (score >= 80) {
    return [const Color(0xFFE8F0E8), const Color(0xFFEFF3EC), const Color(0xFFEAF2EA)];
  } else if (score >= 55) {
    return [const Color(0xFFEFF3EC), const Color(0xFFF2F5EF), const Color(0xFFEFF3EC)];
  } else if (score >= 30) {
    return [const Color(0xFFEDF0EC), const Color(0xFFF2F5EF), const Color(0xFFEDF0EE)];
  } else {
    return [const Color(0xFFF5EFE8), const Color(0xFFF2F5EF), const Color(0xFFF0EDE8)];
  }
}
```

**Step 4: Hot-reload and verify**

Run `flutter run`, navigate all 5 tabs. Everything should be in muted greens and warm ambers. No purple should remain. Check Home, Quests, Insights, Scan, Profile.

---

## Task 2: Leaf Particle Widget — new file

**Files:**
- Create: `lib/widgets/leaf_particle.dart`

A reusable widget that renders a single floating leaf emoji with a randomised drift path. Used by the Mochi intro sequence and the welcome page.

**Step 1: Create the file**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single floating leaf that drifts upward/sideways with a sine-wave wobble.
/// Wrap multiple in a [Stack] with random positions for a forest-particle effect.
class LeafParticle extends StatefulWidget {
  final String emoji;
  final double size;
  final Duration delay;
  final Duration duration;
  final double driftX; // total horizontal drift in logical pixels

  const LeafParticle({
    super.key,
    this.emoji = '🍃',
    this.size = 18,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 2400),
    this.driftX = 30,
  });

  @override
  State<LeafParticle> createState() => _LeafParticleState();
}

class _LeafParticleState extends State<LeafParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        final dx = math.sin(t * math.pi * 2.5) * widget.driftX * 0.5
            + t * widget.driftX;
        final dy = -t * 120; // drift upward
        final opacity = t < 0.15
            ? t / 0.15
            : t > 0.75
                ? (1 - t) / 0.25
                : 1.0;
        final rotate = math.sin(t * math.pi * 3) * 0.4;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: rotate,
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: widget.size),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Step 2: Hot-reload check**

No visible change yet — this widget is unused. Confirm no compile errors with `flutter analyze`.

---

## Task 3: Enhanced MochiPainter — leaf crown + richer Thriving glow

**Files:**
- Modify: `lib/widgets/mochi_widget.dart`

Add an optional `showCrown` flag to `MochiWidget` and `MochiPainter`. When true, two small bezier leaves appear atop Mochi's head. Also deepen the Thriving glow with three layered blur rings.

**Step 1: Add `showCrown` to `MochiWidget`**

Change the class definition and pass-through:

```dart
class MochiWidget extends ConsumerStatefulWidget {
  final double size;
  final bool showThinking;
  final bool showCrown;          // ← add this
  const MochiWidget({
    this.size = 200,
    this.showThinking = false,
    this.showCrown = false,      // ← default false
    super.key,
  });
  // ...
}
```

In the `build` method inside `_MochiWidgetState`, pass `showCrown` to `MochiPainter`:

```dart
child: CustomPaint(
  painter: MochiPainter(
    moodState: mood,
    breathValue: _breathAnim.value,
    showCrown: widget.showCrown,   // ← add
  ),
),
```

**Step 2: Add `showCrown` to `MochiPainter` + leaf crown painter**

Update the constructor:

```dart
class MochiPainter extends CustomPainter {
  final MochiMoodState moodState;
  final double breathValue;
  final bool showCrown;
  const MochiPainter({
    required this.moodState,
    required this.breathValue,
    this.showCrown = false,
  });
```

At the end of the `paint` method (before `canvas.restore()`), add:

```dart
// Leaf crown (intro-only)
if (showCrown) {
  _drawLeafCrown(canvas, cx, headCy, headR);
}
```

Add the new method:

```dart
void _drawLeafCrown(Canvas canvas, double cx, double headCy, double headR) {
  final leafPaint = Paint()..color = const Color(0xFF5BBF8A);
  // Left leaf — bezier teardrop
  final leftPath = Path();
  final lx = cx - headR * 0.28;
  final ty = headCy - headR * 1.05;
  leftPath.moveTo(lx, ty);
  leftPath.quadraticBezierTo(lx - headR * 0.22, ty - headR * 0.28, lx, ty - headR * 0.42);
  leftPath.quadraticBezierTo(lx + headR * 0.10, ty - headR * 0.28, lx, ty);
  canvas.drawPath(leftPath, leafPaint);

  // Right leaf
  final rightPath = Path();
  final rx = cx + headR * 0.28;
  rightPath.moveTo(rx, ty);
  rightPath.quadraticBezierTo(rx + headR * 0.22, ty - headR * 0.28, rx, ty - headR * 0.42);
  rightPath.quadraticBezierTo(rx - headR * 0.10, ty - headR * 0.28, rx, ty);
  canvas.drawPath(rightPath, leafPaint);
}
```

**Step 3: Deepen Thriving glow — replace the single blur circle with three**

Find the `// Glow for Thriving` block in `paint()` and replace it:

```dart
if (moodState == MochiMoodState.thriving) {
  // Outermost soft glow
  canvas.drawCircle(
      Offset(cx, headCy), headR * 1.70,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32));
  // Mid glow
  canvas.drawCircle(
      Offset(cx, headCy), headR * 1.50,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
  // Inner tight glow
  canvas.drawCircle(
      Offset(cx, headCy), headR * 1.28,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
}
```

**Step 4: Update `shouldRepaint`**

```dart
@override
bool shouldRepaint(MochiPainter old) =>
    old.moodState != moodState ||
    old.breathValue != breathValue ||
    old.showCrown != showCrown;
```

**Step 5: Verify**

`flutter run` → Home screen Mochi should now have a deeper warm amber glow when CogniPulse ≥ 80. `showCrown` is still false everywhere so no crown yet.

---

## Task 4: CogniPulse Ring — colour lerp, score counter, pulse, mood switcher

**Files:**
- Modify: `lib/widgets/cognipulse_ring.dart`

Convert `CogniPulseRing` from a `ConsumerWidget` to a `ConsumerStatefulWidget` so it can hold animation controllers.

**Step 1: Full rewrite of `cognipulse_ring.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class CogniPulseRing extends ConsumerStatefulWidget {
  const CogniPulseRing({super.key});
  @override
  ConsumerState<CogniPulseRing> createState() => _CogniPulseRingState();
}

class _CogniPulseRingState extends ConsumerState<CogniPulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(cogniPulseProvider);
    final mood = ref.watch(mochiMoodProvider);
    final delta = MockData.scoreDelta;

    // Pulse when score changes
    if (score != _prevScore) {
      _prevScore = score;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pulseCtrl.forward(from: 0);
      });
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFD8E4D8))),
        ),
        child: Row(children: [
          SizedBox(
            width: 90,
            height: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, ringVal, __) {
                return TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: _moodColor(_prevScore),
                    end: mood.bodyColor,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (_, color, __) => CustomPaint(
                    painter: _RingPainter(ringVal, color ?? mood.bodyColor),
                    child: Center(
                      child: TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: score),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => Text(
                          '$val',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    mood.label,
                    key: ValueKey(mood),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    delta >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: delta >= 0
                        ? AppTheme.successMint
                        : AppTheme.warningAmber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${delta >= 0 ? '+' : ''}$delta from yesterday',
                    style: TextStyle(
                      fontSize: 12,
                      color: delta >= 0
                          ? AppTheme.successMint
                          : AppTheme.warningAmber,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'CogniPulse Score',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Color _moodColor(int score) {
    if (score >= 80) return AppTheme.mochiThriving;
    if (score >= 55) return AppTheme.mochiBalanced;
    if (score >= 30) return AppTheme.mochiDrifting;
    return AppTheme.mochiStruggling;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.44;

    // Subtle glow ring behind track
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    final trackPaint = Paint()
      ..color = const Color(0xFFD4DDD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
```

**Step 2: Verify**

`flutter run` → Home screen CogniPulse ring should now show a sage-green arc with a glow track and an animated score count-up on first load.

---

## Task 5: Quest Cards — Staggered Entrance + Completion Burst

**Files:**
- Modify: `lib/widgets/quest_card.dart`
- Modify: `lib/screens/quests/quests_screen.dart`

**Step 1: Add `index` param to `QuestCard`**

```dart
class QuestCard extends ConsumerWidget {
  final Quest quest;
  final int index;                    // ← add
  const QuestCard({
    required this.quest,
    this.index = 0,                   // ← default 0
    super.key,
  });
```

**Step 2: Replace the `AnimatedContainer` root with staggered entrance**

Import at top:
```dart
import 'package:flutter_animate/flutter_animate.dart';
```

Wrap the `AnimatedContainer` in `.animate()`:

```dart
return AnimatedContainer(
  duration: 350.ms,
  margin: const EdgeInsets.symmetric(vertical: 6),
  decoration: BoxDecoration(
    color: done ? AppTheme.cardSurface.withValues(alpha: 0.4) : AppTheme.cardSurface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFD4DDD4)),
  ),
  child: Stack(
    children: [
      ListTile(
        // ... existing ListTile content unchanged ...
      ),
      // XP burst overlay — shown briefly on completion
      if (done) _XpBurst(xp: quest.xpReward),
    ],
  ),
)
.animate(delay: (index * 60).ms)
.fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
.slideY(begin: 0.25, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
```

**Step 3: Add `_XpBurst` widget at bottom of file**

```dart
class _XpBurst extends StatefulWidget {
  final int xp;
  const _XpBurst({required this.xp});
  @override
  State<_XpBurst> createState() => _XpBurstState();
}

class _XpBurstState extends State<_XpBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _rise = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // Fire once after card appears
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward().then((_) {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      top: 8,
      child: SlideTransition(
        position: _rise,
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            '+${widget.xp} XP',
            style: const TextStyle(
              color: AppTheme.successMint,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Pass index in `QuestsScreen`**

In `quests_screen.dart`, replace:
```dart
...quests.map((q) => QuestCard(quest: q)),
```
with:
```dart
...quests.asMap().entries.map((e) => QuestCard(quest: e.value, index: e.key)),
```

**Step 5: Verify**

Navigate to Quests tab. Cards should cascade in with a 60ms delay between each. Complete a quest — the "+XP" should float upward from the card then fade.

---

## Task 6: Home Screen — Entrance Animation + Hero Tag on Mochi

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

**Step 1: Import `flutter_animate`**

```dart
import 'package:flutter_animate/flutter_animate.dart';
```

**Step 2: Wrap the `SingleChildScrollView` content with entrance animation**

Wrap the `Column` inside `SingleChildScrollView`:

```dart
child: SingleChildScrollView(
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
  child: Column(
    // ... existing children unchanged ...
  )
  .animate()
  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
  .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut),
),
```

**Step 3: Wrap Mochi in Hero tag**

In the `Center` widget that holds `ParticleOverlay`:

```dart
Center(
  child: Hero(
    tag: 'mochi-hero',
    child: ParticleOverlay(
      child: Column(
        children: [
          SizedBox(width: 280, child: MochiDialogueBubble()),
          SizedBox(height: 12),
          MochiWidget(size: 210),
        ],
      ),
    ),
  ),
),
```

**Step 4: Verify**

Hot-reload. The home screen content should fade+slide in on first render. No visible hero effect yet (needs matching tag on another screen).

---

## Task 7: Ambient Background — Forest Gradient Fix

**Files:**
- Modify: `lib/widgets/ambient_background.dart`

The existing `AnimatedContainer` doesn't properly animate gradient changes because Flutter can't tween `BoxDecoration` gradients directly when the gradient changes. Fix by using `TweenAnimationBuilder<double>` + `LinearGradient.lerp`.

**Step 1: Rewrite `AmbientBackground`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class AmbientBackground extends ConsumerStatefulWidget {
  final Widget child;
  const AmbientBackground({required this.child, super.key});

  @override
  ConsumerState<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends ConsumerState<AmbientBackground> {
  List<Color> _prevColors = AppTheme.ambientGradient(70);

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(cogniPulseProvider);
    final targetColors = AppTheme.ambientGradient(score);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOut,
      onEnd: () => _prevColors = targetColors,
      builder: (_, t, child) {
        final interpolated = List.generate(
          targetColors.length,
          (i) => Color.lerp(_prevColors[i], targetColors[i], t)!,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: interpolated,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
```

**Step 2: Verify**

Change CogniPulse score (via debug FAB if hooked, or temporarily hardcode a different value). Background should smoothly transition between gradient states.

---

## Task 8: Onboarding — Progress Dots + Per-Page Stagger + Parallax Transition

**Files:**
- Modify: `lib/screens/onboarding/onboarding_flow.dart`
- Modify: `lib/screens/onboarding/onboarding_pages.dart`

### Part A — Progress dots in OnboardingFlow

**Step 1: Add progress dot indicator to `OnboardingFlow.build`**

In the `Stack` inside `build`, add a `Positioned` progress indicator at the top:

```dart
Positioned(
  top: MediaQuery.of(context).padding.top + 16,
  left: 0,
  right: 0,
  child: _OnboardingDots(current: _page, total: 5),
),
```

**Step 2: Create `_OnboardingDots` widget at bottom of `onboarding_flow.dart`**

```dart
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
```

**Step 3: Update background gradient in `onboarding_pages.dart`**

Find the `_bgGradient` constant and replace it:

```dart
const _bgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF2F5EF), Color(0xFFEFF3EC)],
);
```

Also update the `_PillButton` to use the forest button colour. Find `ElevatedButton` style inside `_PillButton` — it inherits from theme, which now uses `buttonDark = 0xFF2A3828`, so no change needed there.

### Part B — Per-page entrance stagger

**Step 4: Add entrance stagger to `WelcomePage`**

The existing `WelcomePage` has a single fade+slide. Extend it to also stagger the two floating chips with independent delays. In `WelcomePage._WelcomePageState.initState`, add two more animations:

```dart
late final Animation<double> _chip1Fade;
late final Animation<double> _chip2Fade;
```

```dart
// In initState after existing animations:
_chip1Fade = CurvedAnimation(
  parent: _ctrl,
  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
);
_chip2Fade = CurvedAnimation(
  parent: _ctrl,
  curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
);
```

Wrap each `_FloatingChip` in `FadeTransition`:
```dart
Positioned(
  top: 20, right: 20,
  child: FadeTransition(
    opacity: _chip1Fade,
    child: _FloatingChip(text: '✨ AI-powered', color: AppTheme.primaryAccent),
  ),
),
Positioned(
  bottom: 30, left: 10,
  child: FadeTransition(
    opacity: _chip2Fade,
    child: _FloatingChip(text: '🧠 CogniPulse', color: AppTheme.warmAccent),
  ),
),
```

**Step 5: Add stagger to `AvatarSelectionPage` rows**

Convert `_AvatarRow` build in the `ListView.separated` to pass an index delay using `flutter_animate`:

In `AvatarSelectionPage.build`, change `itemBuilder`:

```dart
itemBuilder: (_, i) {
  final av = AvatarSelectionPage._avatars[i];
  return _AvatarRow(
    avatar: av,
    isSelected: _selected == av.id,
    onTap: () => _onSelect(av.id, av.locked),
  )
  .animate(delay: (i * 60).ms)
  .fadeIn(duration: 350.ms)
  .slideX(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
},
```

Add `import 'package:flutter_animate/flutter_animate.dart';` at top of file.

**Step 6: Add stagger to `PermissionsPage` cards**

Replace the three `const _PermissionCard(...)` widgets with staggered versions:

```dart
...[
  const _PermissionCard(
    icon: Icons.keyboard_outlined,
    title: 'Typing patterns',
    description: 'Analyses rhythm and speed — never content. Your words are never read.',
    accentColor: AppTheme.primaryAccent,
  ),
  const _PermissionCard(
    icon: Icons.phone_android_rounded,
    title: 'Phone usage',
    description: 'Session length and app-switching patterns. Nothing identifying.',
    accentColor: AppTheme.warmAccent,
  ),
  const _PermissionCard(
    icon: Icons.face_outlined,
    title: 'Facial scan (optional)',
    description: 'One-time valence reading. Processed on-device. Never stored.',
    accentColor: Color(0xFF6EAAFF),
  ),
].asMap().entries.map((e) => e.value
    .animate(delay: (e.key * 80).ms)
    .fadeIn(duration: 400.ms)
    .slideX(begin: -0.12, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)),
```

Convert `PermissionsPage` from `StatelessWidget` to `StatefulWidget` if needed for the `.animate()` to fire on entry (the stagger fires once on widget creation — stateless is fine).

**Step 7: Verify onboarding**

Reset onboarding via: in `main.dart` temporarily change `initialLocation` or clear shared prefs. Run through all 5 pages. Dots should advance. Avatar rows and permission cards should cascade in.

---

## Task 9: Mochi Cinematic Intro — MeetMochi Page Rewrite

**Files:**
- Modify: `lib/screens/onboarding/onboarding_pages.dart` (MeetMochiPage section)

This is the showpiece. Completely replace `_MeetMochiPageState` with a multi-phase animation sequence.

**Step 1: Replace `MeetMochiPage` state with full cinematic controller**

```dart
class _MeetMochiPageState extends State<MeetMochiPage>
    with TickerProviderStateMixin {
  // Phase controllers
  late final AnimationController _bgCtrl;      // forest bg fade-in
  late final AnimationController _mochiCtrl;   // Mochi growth sequence
  late final AnimationController _textCtrl;    // greeting text
  late final AnimationController _bounceCtrl;  // idle float
  late final AnimationController _leafCtrl;    // leaf burst on tap

  // Animations
  late final Animation<double> _bgFade;
  late final Animation<double> _mochiScale;
  late final Animation<Offset> _mochiSlide;
  late final Animation<double> _glowPulse;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _bounce;

  bool _showContent = false;
  bool _leafBurst = false;
  int _tapCount = 0;

  // Scattered decorations — more leaves for forest feel
  final _decorations = const [
    _Decoration(emoji: '🌿', top: 80,  left: 24,  size: 22),
    _Decoration(emoji: '🍃', top: 130, right: 20, size: 18),
    _Decoration(emoji: '🌱', top: 240, left: 16,  size: 16),
    _Decoration(emoji: '✨', bottom: 210, right: 28, size: 20),
    _Decoration(emoji: '🌸', bottom: 170, left: 22, size: 18),
    _Decoration(emoji: '🍀', top: 320, right: 14,  size: 14),
  ];

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: 600.ms);
    _mochiCtrl = AnimationController(vsync: this, duration: 1000.ms);
    _textCtrl = AnimationController(vsync: this, duration: 600.ms);
    _bounceCtrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _leafCtrl = AnimationController(vsync: this, duration: 400.ms);

    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    _mochiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mochiCtrl, curve: Curves.elasticOut));
    _mochiSlide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _mochiCtrl, curve: Curves.easeOutCubic));

    _glowPulse = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _mochiCtrl, curve: Curves.easeOut));

    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _bounce = Tween<double>(begin: -5.0, end: 5.0).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(150.ms);
    _bgCtrl.forward();
    await Future.delayed(500.ms);
    _mochiCtrl.forward();
    await Future.delayed(900.ms);
    if (mounted) setState(() => _showContent = true);
    _textCtrl.forward();
  }

  void _onMochiTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _tapCount++;
      _leafBurst = true;
    });
    _leafCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _leafBurst = false);
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _mochiCtrl.dispose();
    _textCtrl.dispose();
    _bounceCtrl.dispose();
    _leafCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name.trim().isNotEmpty ? widget.name.trim() : 'you';

    return FadeTransition(
      opacity: _bgFade,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F5EF), Color(0xFFE8F0E8), Color(0xFFEFF3EC)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Forest decoration emojis
              for (final d in _decorations) _buildDecoration(d),

              // Leaf burst on tap
              if (_leafBurst) ..._buildLeafBurst(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Mochi reveal
                    GestureDetector(
                      onTap: _onMochiTap,
                      child: SlideTransition(
                        position: _mochiSlide,
                        child: ScaleTransition(
                          scale: _mochiScale,
                          child: AnimatedBuilder(
                            animation: _bounce,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _bounce.value),
                              child: child,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow circle — pulses as Mochi enters
                                ScaleTransition(
                                  scale: _glowPulse,
                                  child: Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.10),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Larger outer glow
                                Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Mochi with leaf crown!
                                const MochiWidget(size: 190, showCrown: true),
                                // Tap hint (shown before first tap)
                                if (_tapCount == 0 && _showContent)
                                  Positioned(
                                    bottom: 18,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '👆 tap Mochi!',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Greeting — fades in after Mochi arrives
                    if (_showContent) ...[
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              Text(
                                'Meet Mochi! 🌿',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 18),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.20)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(children: [
                                  Text(
                                    "Hey $displayName! I'm Mochi 🐻",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "I'll keep an eye on how you're doing and check in when it matters. Let's grow together 🌱",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 120),

                    const Spacer(flex: 2),

                    if (_showContent)
                      FadeTransition(
                        opacity: _textFade,
                        child: _PillButton(
                          label: "Let's thrive 🌿",
                          onPressed: widget.onFinish,
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecoration(_Decoration d) {
    return Positioned(
      top: d.top, bottom: d.bottom, left: d.left, right: d.right,
      child: AnimatedBuilder(
        animation: _textFade,
        builder: (_, __) => Opacity(
          opacity: _showContent ? (_textFade.value * 0.55) : 0,
          child: Text(d.emoji, style: TextStyle(fontSize: d.size)),
        ),
      ),
    );
  }

  List<Widget> _buildLeafBurst(BuildContext context) {
    final center = MediaQuery.of(context).size;
    return List.generate(6, (i) {
      final angle = i * (math.pi * 2 / 6);
      return Positioned(
        left: center.width / 2 - 8,
        top: center.height * 0.40,
        child: AnimatedBuilder(
          animation: _leafCtrl,
          builder: (_, __) {
            final t = _leafCtrl.value;
            final r = t * 60;
            final dx = math.cos(angle) * r;
            final dy = math.sin(angle) * r - t * 30;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: const Text('🍃', style: TextStyle(fontSize: 16)),
              ),
            );
          },
        ),
      );
    });
  }
}
```

**Add `import 'dart:math' as math;`** at top if not already present (it is — line 1 of the file).
**Add `import 'package:flutter/services.dart';`** if not already present (it is — existing file has it).

**Step 2: Verify**

Navigate through onboarding to the MeetMochi page. Mochi should:
1. Fade in on a forest-green gradient bg
2. Slide up + elastic pop with leaf crown visible
3. Float gently
4. Greeting text fade in
5. Tapping Mochi → leaf burst radial from centre + haptic

---

## Task 10: Animated Bottom Nav Indicator

**Files:**
- Modify: `lib/router/scaffold_with_nav.dart`

**Step 1: Read current `scaffold_with_nav.dart` first**

Check what the current bottom nav looks like. The standard `BottomNavigationBar` uses the theme's `selectedItemColor`. To add an animated indicator bar, we replace it with a custom `NavigationBar` or keep `BottomNavigationBar` but add a `Stack` overlay indicator.

**Step 2: Add forest-coloured animated pill indicator**

In `scaffold_with_nav.dart`, wrap the `BottomNavigationBar` in a `Stack` and add a sliding indicator pill. The simplest approach — add `indicator` to existing `BottomNavigationBar` via its `selectedItemColor` + `showSelectedLabels` from theme.

Add an `AnimatedContainer` pill above the nav items. In the `Scaffold`, change:

```dart
bottomNavigationBar: BottomNavigationBar(
  currentIndex: shell.currentIndex,
  onTap: (i) => _onTap(context, shell, i),
  items: [...],
),
```

to wrap in a `Column` inside a `SizedBox`:

```dart
bottomNavigationBar: SizedBox(
  height: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
  child: Stack(
    children: [
      BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => _onTap(context, shell, i),
        items: [...],
      ),
      // Animated top-border indicator
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: LayoutBuilder(builder: (_, constraints) {
          final tabCount = 5;
          final tabWidth = constraints.maxWidth / tabCount;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(
              left: shell.currentIndex * tabWidth + tabWidth * 0.25,
              right: (tabCount - shell.currentIndex - 1) * tabWidth + tabWidth * 0.25,
            ),
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF7AB87A),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    ],
  ),
),
```

**Step 3: Verify**

Switch tabs — a sage-green pill bar should slide smoothly between tab positions.

---

## Task 11: All Screens — Lightweight Entrance Animations

**Files:**
- Modify: `lib/screens/insights/insights_screen.dart`
- Modify: `lib/screens/scan/scan_screen.dart`
- Modify: `lib/screens/profile/profile_screen.dart`

In each screen, read the file first, then wrap the root scroll `Column` with:

```dart
import 'package:flutter_animate/flutter_animate.dart';

// Wrap the Column (or ListView) inside SingleChildScrollView:
.animate()
.fadeIn(duration: 300.ms, curve: Curves.easeOut)
.slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut)
```

This is a 3-minute change per screen. Do each screen separately and hot-reload to verify.

---

## Task 12: Final Integration Check + pubspec verify

**Step 1: Confirm pubspec has `flutter_animate`**

```bash
grep flutter_animate pubspec.yaml
```

Should show something like `flutter_animate: ^4.x.x`. If not:
```bash
flutter pub add flutter_animate
```

**Step 2: Run full static analysis**

```bash
flutter analyze
```

Fix any warnings about unused imports, missing `const`, or deprecated APIs before proceeding.

**Step 3: Smoke test all 5 tabs**

```bash
flutter run
```

Checklist:
- [ ] Home: forest bg, Mochi with warm amber glow (if Thriving), entrance fade
- [ ] Quests: cards stagger in, XP burst on completion
- [ ] Insights: entrance animation
- [ ] Scan: entrance animation
- [ ] Profile: entrance animation
- [ ] Bottom nav: green pill indicator slides between tabs
- [ ] Onboarding (reset prefs to test): dots advance, per-page stagger, MeetMochi cinematic with leaf crown + tap burst

**Step 4: Test CogniPulse ring**

Temporarily change `cogniPulseProvider` to a different score value and hot-reload. Ring should smoothly transition colour and count.

---

## Implementation Order Summary

| # | Task | Time estimate |
|---|---|---|
| 1 | Forest palette (`app_theme.dart`) | 10 min |
| 2 | Leaf particle widget | 10 min |
| 3 | Enhanced MochiPainter (crown + glow) | 15 min |
| 4 | CogniPulse ring (colour lerp, counter, pulse) | 20 min |
| 5 | Quest cards stagger + XP burst | 20 min |
| 6 | Home screen entrance + hero tag | 5 min |
| 7 | Ambient background gradient lerp | 10 min |
| 8 | Onboarding: dots + per-page stagger | 20 min |
| 9 | MeetMochi cinematic rewrite | 30 min |
| 10 | Animated bottom nav indicator | 10 min |
| 11 | Insights/Scan/Profile entrance anims | 10 min |
| 12 | Final integration + analyze | 10 min |

**Total: ~2.5 hours of implementation**
