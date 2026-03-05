import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/ollama_service.dart';

class MochiWidget extends ConsumerStatefulWidget {
  final double size;
  final bool showThinking;
  final bool showCrown;
  const MochiWidget({this.size = 200, this.showThinking = false, this.showCrown = false, super.key});

  @override
  ConsumerState<MochiWidget> createState() => _MochiWidgetState();
}

class _MochiWidgetState extends ConsumerState<MochiWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _tapCtrl;
  late final Animation<double> _breathAnim;
  late final Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(vsync: this, duration: 2000.ms)
      ..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _tapCtrl = AnimationController(vsync: this, duration: 600.ms);
    _tapAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0);

    ref.read(mochiLoadingProvider.notifier).state = true;
    final score = ref.read(cogniPulseProvider);
    final mood = ref.read(mochiMoodProvider);
    final line = await ref.read(ollamaServiceProvider).getMochiDialogue(
          cogniPulseScore: score,
          moodState: mood,
          setOllamaStatus: (live) =>
              ref.read(appStateProvider.notifier).setOllamaStatus(live),
        );
    ref.read(mochiDialogueProvider.notifier).state = line;
    ref.read(mochiLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(mochiMoodProvider);
    final thinking = ref.watch(mochiLoadingProvider);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnim, _tapAnim]),
        builder: (context, _) {
          Widget mochi = Transform.scale(
            scale: _tapAnim.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: MochiPainter(
                  moodState: mood,
                  breathValue: _breathAnim.value,
                  showCrown: widget.showCrown,
                ),
              ),
            ),
          );

          if (thinking) {
            mochi = mochi
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 600.ms, begin: -0.04, end: 0.04)
                .then()
                .rotate(duration: 600.ms, begin: 0.04, end: -0.04);
          }
          return mochi;
        },
      ),
    );
  }
}

// ─── Mochi CustomPainter ──────────────────────────────────────────────────

class MochiPainter extends CustomPainter {
  final MochiMoodState moodState;
  final double breathValue;
  final bool showCrown;
  const MochiPainter({required this.moodState, required this.breathValue, this.showCrown = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5;

    final bs = 1.0 + breathValue * 0.03;
    canvas.save();
    canvas.translate(cx, h * 0.5);
    canvas.scale(bs, bs);
    canvas.translate(-cx, -h * 0.5);

    final bodyColor = moodState.bodyColor;
    final paint = Paint()..color = bodyColor;
    final darkPaint = Paint()..color = const Color(0xFF1E1040);
    final nosePaint = Paint()..color = const Color(0xFF4A2D7A).withValues(alpha: 0.85);

    final headCy = h * 0.40;
    final headR = w * 0.295;
    final bellyCy = h * 0.70;
    final bellyR = w * 0.225;
    final earR = w * 0.095;
    final leftEar = Offset(cx - headR * 0.67, headCy - headR * 0.73);
    final rightEar = Offset(cx + headR * 0.67, headCy - headR * 0.73);

    // Glow for Thriving — three layered blur rings
    if (moodState == MochiMoodState.thriving) {
      canvas.drawCircle(
          Offset(cx, headCy), headR * 1.70,
          Paint()
            ..color = bodyColor.withValues(alpha: 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32));
      canvas.drawCircle(
          Offset(cx, headCy), headR * 1.50,
          Paint()
            ..color = bodyColor.withValues(alpha: 0.13)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
      canvas.drawCircle(
          Offset(cx, headCy), headR * 1.28,
          Paint()
            ..color = bodyColor.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    // Belly
    canvas.drawCircle(Offset(cx, bellyCy), bellyR, paint);
    canvas.drawCircle(
        Offset(cx - bellyR * 0.22, bellyCy - bellyR * 0.22),
        bellyR * 0.48,
        Paint()..color = Colors.white.withValues(alpha: 0.12));

    // Head
    canvas.drawCircle(Offset(cx, headCy), headR, paint);
    canvas.drawCircle(
        Offset(cx - headR * 0.30, headCy - headR * 0.30),
        headR * 0.38,
        Paint()..color = Colors.white.withValues(alpha: 0.10));

    // Ears
    final innerEarColor = moodState == MochiMoodState.thriving
        ? const Color(0xFFFFCB8E)
        : Color.lerp(bodyColor, Colors.white, 0.2)!;
    canvas.drawCircle(leftEar, earR, paint);
    canvas.drawCircle(rightEar, earR, paint);
    canvas.drawCircle(leftEar, earR * 0.58, Paint()..color = innerEarColor);
    canvas.drawCircle(rightEar, earR * 0.58, Paint()..color = innerEarColor);

    // Eyes
    final eyeY = headCy - headR * 0.04;
    final leftX = cx - headR * 0.305;
    final rightX = cx + headR * 0.305;
    final eyeR = headR * 0.115;
    _drawEyes(canvas, leftX, rightX, eyeY, eyeR, darkPaint, bodyColor);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headCy + headR * 0.16),
          width: eyeR * 2.2,
          height: eyeR * 1.4),
      nosePaint,
    );

    // Mouth
    _drawMouth(canvas, cx, headCy, headR, darkPaint);

    // Leaf crown (intro-only)
    if (showCrown) {
      _drawLeafCrown(canvas, cx, headCy, headR);
    }

    canvas.restore();
  }

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

  void _drawEyes(Canvas canvas, double lx, double rx, double y, double r,
      Paint dark, Color bodyColor) {
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.88);
    switch (moodState) {
      case MochiMoodState.thriving:
        canvas.drawCircle(Offset(lx, y), r * 1.12, dark);
        canvas.drawCircle(Offset(rx, y), r * 1.12, dark);
        canvas.drawCircle(Offset(lx + r * 0.35, y - r * 0.35), r * 0.38, shine);
        canvas.drawCircle(Offset(rx + r * 0.35, y - r * 0.35), r * 0.38, shine);

      case MochiMoodState.balanced:
        canvas.drawCircle(Offset(lx, y), r, dark);
        canvas.drawCircle(Offset(rx, y), r, dark);
        canvas.drawCircle(Offset(lx + r * 0.28, y - r * 0.28), r * 0.32, shine);
        canvas.drawCircle(Offset(rx + r * 0.28, y - r * 0.28), r * 0.32, shine);

      case MochiMoodState.drifting:
        canvas.drawCircle(Offset(lx, y), r, dark);
        canvas.drawCircle(Offset(rx, y), r, dark);
        final lidPaint = Paint()..color = bodyColor;
        canvas.drawRect(
            Rect.fromLTWH(lx - r * 1.1, y - r * 1.1, r * 2.2, r * 1.05), lidPaint);
        canvas.drawRect(
            Rect.fromLTWH(rx - r * 1.1, y - r * 1.1, r * 2.2, r * 1.05), lidPaint);

      case MochiMoodState.struggling:
        canvas.drawCircle(Offset(lx, y + r * 0.4), r * 0.82, dark);
        canvas.drawCircle(Offset(rx, y + r * 0.4), r * 0.82, dark);
        final tearPaint = Paint()..color = const Color(0xFF88AACC).withValues(alpha: 0.6);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(lx, y + r * 1.6), width: r * 0.6, height: r * 0.9),
            tearPaint);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double headCy, double headR, Paint dark) {
    final mouthPaint = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.065
      ..strokeCap = StrokeCap.round;
    final my = headCy + headR * 0.37;
    final mw = headR * 0.33;
    final path = Path();
    switch (moodState) {
      case MochiMoodState.thriving:
        path.moveTo(cx - mw, my);
        path.quadraticBezierTo(cx, my + headR * 0.22, cx + mw, my);
      case MochiMoodState.balanced:
        path.moveTo(cx - mw * 0.8, my);
        path.quadraticBezierTo(cx, my + headR * 0.13, cx + mw * 0.8, my);
      case MochiMoodState.drifting:
        path.moveTo(cx - mw * 0.55, my);
        path.quadraticBezierTo(cx, my + headR * 0.04, cx + mw * 0.55, my);
      case MochiMoodState.struggling:
        path.moveTo(cx - mw * 0.45, my + headR * 0.06);
        path.quadraticBezierTo(cx, my - headR * 0.06, cx + mw * 0.45, my + headR * 0.06);
    }
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(MochiPainter old) =>
      old.moodState != moodState ||
      old.breathValue != breathValue ||
      old.showCrown != showCrown;
}
