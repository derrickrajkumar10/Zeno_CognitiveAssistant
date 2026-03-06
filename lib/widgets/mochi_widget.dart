import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

/// The Mochi character widget — a living, breathing companion.
///
/// Features:
/// - Mood-reactive body color and expressions
/// - Idle animations: breathing, blinking, looking around
/// - Tap reactions: squish, bounce, yawn, nod
/// - Ambient glow based on mood
class MochiWidget extends ConsumerStatefulWidget {
  final double size;
  final bool showCrown;
  final bool interactive;

  const MochiWidget({
    super.key,
    this.size = 200,
    this.showCrown = false,
    this.interactive = true,
  });

  @override
  ConsumerState<MochiWidget> createState() => _MochiWidgetState();
}

class _MochiWidgetState extends ConsumerState<MochiWidget>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────
  late final AnimationController _breathCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _lookCtrl;
  late final AnimationController _tapCtrl;
  late final AnimationController _earCtrl;

  // ── Animation values ───────────────────────────────────────────────────
  late final Animation<double> _breathAnim;
  late final Animation<double> _blinkAnim;
  late final Animation<Offset> _lookAnim;
  late final Animation<double> _tapAnim;

  // ── State ──────────────────────────────────────────────────────────────
  bool _isBlinking = false;
  Offset _eyeOffset = Offset.zero;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();

    // Breathing — continuous gentle pulse
    _breathCtrl = AnimationController(vsync: this, duration: 2500.ms)
      ..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    // Blink — triggered randomly
    _blinkCtrl = AnimationController(vsync: this, duration: 150.ms);
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _blinkCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkCtrl.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _isBlinking = false);
        _scheduleBlink();
      }
    });
    _scheduleBlink();

    // Looking around — random eye drift
    _lookCtrl = AnimationController(vsync: this, duration: 2000.ms);
    _lookAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _lookCtrl, curve: Curves.easeInOut),
    );
    _scheduleLook();

    // Tap reaction — spring bounce
    _tapCtrl = AnimationController(vsync: this, duration: 500.ms);
    _tapAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.12), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.97), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));

    // Ear twitch
    _earCtrl = AnimationController(vsync: this, duration: 300.ms);
    _scheduleEarTwitch();
  }

  void _scheduleBlink() {
    final delay = 2500 + Random().nextInt(4000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      _blinkCtrl.forward();
    });
  }

  void _scheduleLook() {
    final delay = 4000 + Random().nextInt(6000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final dx = (Random().nextDouble() - 0.5) * 6;
      final dy = (Random().nextDouble() - 0.5) * 3;
      setState(() => _eyeOffset = Offset(dx, dy));
      _scheduleLook();
    });
  }

  void _scheduleEarTwitch() {
    final delay = 8000 + Random().nextInt(8000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _earCtrl.forward().then((_) => _earCtrl.reverse());
      _scheduleEarTwitch();
    });
  }

  void _handleTap() {
    if (!widget.interactive) return;
    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0);
    _tapCount++;

    // Cycle to next dialogue on tap
    ref.read(appStateProvider.notifier).cycleDialogue();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _blinkCtrl.dispose();
    _lookCtrl.dispose();
    _tapCtrl.dispose();
    _earCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(appStateProvider).cogniPulseScore;
    final mood = MochiMoodStateX.fromScore(score);
    final size = widget.size;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnim, _tapAnim, _blinkAnim]),
        builder: (context, child) {
          final breathScale = 1.0 + (_breathAnim.value * 0.035);
          final tapScale = _tapAnim.value;

          return Transform.scale(
            scale: breathScale * tapScale,
            child: SizedBox(
              width: size,
              height: size * 1.1,
              child: CustomPaint(
                painter: _MochiPainter(
                  mood: mood,
                  blinkValue: _blinkAnim.value,
                  eyeOffset: _eyeOffset,
                  showCrown: widget.showCrown,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOCHI CUSTOM PAINTER — The visual heart
// ═════════════════════════════════════════════════════════════════════════════

class _MochiPainter extends CustomPainter {
  final MochiMoodState mood;
  final double blinkValue; // 1.0 = open, 0.0 = closed
  final Offset eyeOffset;
  final bool showCrown;

  _MochiPainter({
    required this.mood,
    required this.blinkValue,
    required this.eyeOffset,
    required this.showCrown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final bodyR = size.width * 0.36;

    // ── Ambient glow ─────────────────────────────────────────────────────
    final glowPaint = Paint()
      ..color = mood.glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(cx, cy + bodyR * 0.15), bodyR * 1.1, glowPaint);

    // ── Shadow ───────────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x15000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bodyR + 8),
        width: bodyR * 1.3,
        height: 12,
      ),
      shadowPaint,
    );

    // ── Body ─────────────────────────────────────────────────────────────
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 1.2,
      colors: [
        _lighten(mood.bodyColor, 0.15),
        mood.bodyColor,
        _darken(mood.bodyColor, 0.1),
      ],
    );
    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: bodyR),
      );
    canvas.drawCircle(Offset(cx, cy), bodyR, bodyPaint);

    // ── Belly patch ──────────────────────────────────────────────────────
    final bellyPaint = Paint()..color = Colors.white.withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bodyR * 0.2),
        width: bodyR * 0.9,
        height: bodyR * 0.7,
      ),
      bellyPaint,
    );

    // ── Ears ─────────────────────────────────────────────────────────────
    _drawEar(canvas, cx - bodyR * 0.62, cy - bodyR * 0.72, bodyR * 0.3,
        mood.bodyColor, -0.2);
    _drawEar(canvas, cx + bodyR * 0.62, cy - bodyR * 0.72, bodyR * 0.3,
        mood.bodyColor, 0.2);

    // ── Eyes ─────────────────────────────────────────────────────────────
    final eyeY = cy - bodyR * 0.12;
    final eyeSpacing = bodyR * 0.32;
    _drawEye(canvas, cx - eyeSpacing + eyeOffset.dx, eyeY + eyeOffset.dy,
        bodyR * 0.12, blinkValue, mood);
    _drawEye(canvas, cx + eyeSpacing + eyeOffset.dx, eyeY + eyeOffset.dy,
        bodyR * 0.12, blinkValue, mood);

    // ── Blush marks ──────────────────────────────────────────────────────
    final blushPaint = Paint()
      ..color = const Color(0x30FF8A80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - bodyR * 0.48, cy + bodyR * 0.05),
          width: bodyR * 0.22,
          height: bodyR * 0.13),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + bodyR * 0.48, cy + bodyR * 0.05),
          width: bodyR * 0.22,
          height: bodyR * 0.13),
      blushPaint,
    );

    // ── Nose ─────────────────────────────────────────────────────────────
    final nosePaint = Paint()..color = _darken(mood.bodyColor, 0.25);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + bodyR * 0.08),
          width: bodyR * 0.09,
          height: bodyR * 0.06),
      nosePaint,
    );

    // ── Mouth ────────────────────────────────────────────────────────────
    _drawMouth(canvas, cx, cy + bodyR * 0.18, bodyR, mood);

    // ── Arms ─────────────────────────────────────────────────────────────
    _drawArm(canvas, cx - bodyR * 0.85, cy + bodyR * 0.2, bodyR * 0.2,
        mood.bodyColor, true);
    _drawArm(canvas, cx + bodyR * 0.85, cy + bodyR * 0.2, bodyR * 0.2,
        mood.bodyColor, false);

    // ── Feet ─────────────────────────────────────────────────────────────
    final footPaint = Paint()..color = _darken(mood.bodyColor, 0.08);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - bodyR * 0.35, cy + bodyR * 0.88),
          width: bodyR * 0.3,
          height: bodyR * 0.18),
      footPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + bodyR * 0.35, cy + bodyR * 0.88),
          width: bodyR * 0.3,
          height: bodyR * 0.18),
      footPaint,
    );

    // ── Leaf crown ───────────────────────────────────────────────────────
    if (showCrown) {
      _drawLeafCrown(canvas, cx, cy - bodyR * 0.82, bodyR * 0.35);
    }
  }

  void _drawEar(
      Canvas canvas, double x, double y, double r, Color color, double tilt) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(tilt);
    // Outer ear
    canvas.drawCircle(Offset.zero, r, Paint()..color = color);
    // Inner ear
    canvas.drawCircle(Offset(0, r * 0.1), r * 0.6,
        Paint()..color = Color.lerp(color, const Color(0xFFFFB4AB), 0.35)!);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, double x, double y, double r, double blink,
      MochiMoodState mood) {
    final eyeHeight = r * 2 * blink;
    if (eyeHeight < 1) {
      // Closed eye — draw a line
      final linePaint = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(x - r * 0.7, y), Offset(x + r * 0.7, y), linePaint);
      return;
    }

    // Eye white
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: r * 2, height: eyeHeight),
      Paint()..color = Colors.white,
    );

    // Pupil
    final pupilR = r * 0.55;
    canvas.drawCircle(
      Offset(x, y),
      pupilR,
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // Eye shine
    canvas.drawCircle(
      Offset(x - pupilR * 0.35, y - pupilR * 0.35),
      pupilR * 0.35,
      Paint()..color = Colors.white,
    );

    // Mood-specific eye detail
    if (mood == MochiMoodState.thriving) {
      // Sparkly eyes — extra small shine
      canvas.drawCircle(
        Offset(x + pupilR * 0.25, y + pupilR * 0.15),
        pupilR * 0.15,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }
    if (mood == MochiMoodState.drifting || mood == MochiMoodState.struggling) {
      // Half-lidded — draw eyelid
      final lidPaint = Paint()..color = mood.bodyColor;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(x, y), width: r * 2.1, height: eyeHeight + 2),
        pi,
        pi,
        true,
        lidPaint,
      );
      // Redraw lower half of eye
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(x, y + r * 0.15),
            width: r * 1.8,
            height: eyeHeight * 0.6),
        0,
        pi,
        true,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x, y + r * 0.15),
        pupilR * 0.5,
        Paint()..color = const Color(0xFF2A2A2A),
      );
      canvas.drawCircle(
        Offset(x - pupilR * 0.2, y + r * 0.05),
        pupilR * 0.2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawMouth(
      Canvas canvas, double cx, double y, double bodyR, MochiMoodState mood) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = bodyR * 0.22;

    switch (mood) {
      case MochiMoodState.thriving:
        // Big happy smile
        final path = Path()
          ..moveTo(cx - w, y)
          ..quadraticBezierTo(cx, y + w * 0.8, cx + w, y);
        canvas.drawPath(path, paint);
        break;
      case MochiMoodState.balanced:
        // Gentle smile
        final path = Path()
          ..moveTo(cx - w * 0.7, y)
          ..quadraticBezierTo(cx, y + w * 0.45, cx + w * 0.7, y);
        canvas.drawPath(path, paint);
        break;
      case MochiMoodState.drifting:
        // Neutral/slightly down
        canvas.drawLine(
            Offset(cx - w * 0.5, y), Offset(cx + w * 0.5, y), paint);
        break;
      case MochiMoodState.struggling:
        // Slight frown
        final path = Path()
          ..moveTo(cx - w * 0.6, y)
          ..quadraticBezierTo(cx, y - w * 0.3, cx + w * 0.6, y);
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawArm(
      Canvas canvas, double x, double y, double r, Color color, bool isLeft) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(isLeft ? -0.3 : 0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r, height: r * 1.6),
      Paint()..color = _darken(color, 0.05),
    );
    canvas.restore();
  }

  void _drawLeafCrown(Canvas canvas, double cx, double y, double size) {
    final leafPaint = Paint()..color = AppTheme.primaryLight;
    // Center leaf
    _drawLeaf(canvas, cx, y - size * 0.2, size * 0.5, 0, leafPaint);
    // Left leaf
    _drawLeaf(canvas, cx - size * 0.4, y, size * 0.4, -0.4, leafPaint);
    // Right leaf
    _drawLeaf(canvas, cx + size * 0.4, y, size * 0.4, 0.4, leafPaint);
  }

  void _drawLeaf(Canvas canvas, double x, double y, double size, double angle,
      Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.5, -size * 0.3, 0, size * 0.2)
      ..quadraticBezierTo(-size * 0.5, -size * 0.3, 0, -size);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _MochiPainter old) =>
      old.mood != mood ||
      old.blinkValue != blinkValue ||
      old.eyeOffset != eyeOffset ||
      old.showCrown != showCrown;
}
