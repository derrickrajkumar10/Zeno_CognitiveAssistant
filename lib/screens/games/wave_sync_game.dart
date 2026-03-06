import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class WaveSyncGame extends StatelessWidget {
  const WaveSyncGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'wave_sync',
      gameTitle: 'Wave Sync',
      xpReward: 35,
      gameBuilder: (controller) => _WaveSyncPlay(controller: controller),
    );
  }
}

class _WaveSyncPlay extends StatefulWidget {
  final GameWrapperState controller;

  const _WaveSyncPlay({required this.controller});

  @override
  State<_WaveSyncPlay> createState() => _WaveSyncPlayState();
}

class _WaveSyncPlayState extends State<_WaveSyncPlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  static const _cycleDurationSec = 19.0;
  static const _maxTaps = 15;
  static const _crestWindow = 0.03;

  int _taps = 0;
  int _goodTaps = 0;
  int _round = 1;
  bool _gameOver = false;
  bool _wasNearCrest = false;

  double get _crestPosition => 4.0 / _cycleDurationSec;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_cycleDurationSec * 1000).round()),
    )
      ..addListener(_trackStimulus)
      ..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _trackStimulus() {
    final distance = (_waveController.value - _crestPosition).abs();
    final circularDistance = min(distance, 1 - distance);
    final nearCrest = circularDistance <= _crestWindow;

    if (nearCrest && !_wasNearCrest) {
      widget.controller.markStimulus();
    }

    _wasNearCrest = nearCrest;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_gameOver) {
      return;
    }

    HapticFeedback.lightImpact();
    _taps++;

    final distance = (_waveController.value - _crestPosition).abs();
    final circularDistance = min(distance, 1 - distance);
    final deviationMs = (circularDistance * _cycleDurationSec * 1000).round();
    final isGood = circularDistance < 0.08;

    if (isGood) {
      _goodTaps++;
      _round++;
    }

    widget.controller.recordTouch(
      reactionTimeMs: deviationMs,
      tapPressure: event.pressure,
      tapPosition: event.position,
      eventType: isGood ? 'tap_hit' : 'tap_miss',
      gameContext: {
        'wave_position': _waveController.value,
        'deviation_ms': deviationMs,
        'round': _round,
      },
    );

    if (_taps >= _maxTaps) {
      _gameOver = true;
      final score = (_goodTaps / _maxTaps * 100).round();
      widget.controller.endGame(score: score, levelReached: _round);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          children: [
            Text('Tap at the crest', style: AppTheme.headlineMed),
            const SizedBox(height: AppTheme.xs),
            Text('$_goodTaps / $_taps accurate', style: AppTheme.bodySmall),
            const Spacer(),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(MediaQuery.of(context).size.width - 48, 200),
                    painter: _WavePainter(
                      progress: _waveController.value,
                      crestPosition: _crestPosition,
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            Text('4-7-8 Rhythm', style: AppTheme.caption),
            const SizedBox(height: AppTheme.sm),
            _BreathPhaseIndicator(progress: _waveController.value),
            const SizedBox(height: AppTheme.xl),
          ],
        ),
      ),
    );
  }
}

class _BreathPhaseIndicator extends StatelessWidget {
  final double progress;

  const _BreathPhaseIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final phase = progress < 4 / 19
        ? 'Inhale...'
        : progress < 11 / 19
            ? 'Hold...'
            : 'Exhale...';
    return Text(
      phase,
      style: AppTheme.headlineLarge.copyWith(color: AppTheme.primary),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double crestPosition;

  _WavePainter({required this.progress, required this.crestPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    path.moveTo(0, midY);
    for (double x = 0; x <= width; x += 2) {
      final t = x / width;
      final wave = sin((t - progress) * 2 * pi) * (height * 0.35);
      path.lineTo(x, midY - wave);
    }
    canvas.drawPath(path, wavePaint);

    final crestX = ((crestPosition + progress) % 1.0) * width;
    final markerPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(crestX, midY - height * 0.35), 8, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
