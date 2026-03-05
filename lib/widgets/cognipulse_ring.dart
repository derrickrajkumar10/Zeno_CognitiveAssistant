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
