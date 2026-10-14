import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class BubbleDriftGame extends StatelessWidget {
  const BubbleDriftGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'bubble_drift',
      gameTitle: 'Bubble Drift',
      xpReward: 30,
      gameBuilder: (controller) => _BubbleDriftPlay(controller: controller),
    );
  }
}

class _BubbleDriftPlay extends StatefulWidget {
  final GameWrapperState controller;
  const _BubbleDriftPlay({required this.controller});

  @override
  State<_BubbleDriftPlay> createState() => _BubbleDriftPlayState();
}

class _Bubble {
  double x, y, radius, speed;
  bool popped = false;
  final DateTime spawnTime;
  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.spawnTime,
  });
}

class _BubbleDriftPlayState extends State<_BubbleDriftPlay>
    with TickerProviderStateMixin {
  final _rng = Random();
  final List<_Bubble> _bubbles = [];
  late AnimationController _ticker;
  int _score = 0;
  int _misses = 0;
  int _wave = 1;
  int _bubblesThisWave = 0;
  int _bubblesPerWave = 5;
  double _baseSpeed = 0.8;
  bool _gameOver = false;
  static const _maxMisses = 10;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _ticker.repeat();
    // MediaQuery can't be read until initState has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _spawnBubble();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnBubble() {
    if (_gameOver) return;
    final size = MediaQuery.sizeOf(context);
    final radius = 20.0 + _rng.nextDouble() * 20;
    final bubble = _Bubble(
      x: radius + _rng.nextDouble() * (size.width - radius * 2),
      y: size.height,
      radius: radius,
      speed: _baseSpeed + _rng.nextDouble() * 0.5,
      spawnTime: DateTime.now(),
    );
    setState(() => _bubbles.add(bubble));
    widget.controller.markStimulus();
  }

  void _update() {
    if (_gameOver) return;
    setState(() {
      for (final b in _bubbles) {
        if (!b.popped) b.y -= b.speed;
      }
      // Check for escaped bubbles
      final escaped = _bubbles.where((b) => !b.popped && b.y < -50).toList();
      for (final bubble in escaped) {
        _misses++;
        widget.controller.recordTouch(
          reactionTimeMs: DateTime.now().difference(bubble.spawnTime).inMilliseconds,
          eventType: 'tap_miss',
          gameContext: {'reason': 'escaped', 'wave': _wave},
        );
      }
      _bubbles.removeWhere((b) => b.popped || b.y < -50);

      // Spawn new bubbles
      if (_rng.nextDouble() < 0.03 * _wave && _bubblesThisWave < _bubblesPerWave) {
        _bubblesThisWave++;
        _spawnBubble();
      }

      // Next wave
      if (_bubblesThisWave >= _bubblesPerWave && _bubbles.where((b) => !b.popped).isEmpty) {
        _wave++;
        _bubblesThisWave = 0;
        _bubblesPerWave = (_bubblesPerWave + 2).clamp(0, 20);
        _baseSpeed += 0.15;
      }

      if (_misses >= _maxMisses) {
        _gameOver = true;
        final pct = (_score / (_score + _misses) * 100).round();
        widget.controller.endGame(score: pct, levelReached: _wave);
      }
    });
  }

  void _tapBubble(_Bubble bubble, Offset pos, double pressure) {
    if (bubble.popped || _gameOver) return;
    HapticFeedback.lightImpact();
    final rt = DateTime.now().difference(bubble.spawnTime).inMilliseconds;
    widget.controller.recordTouch(
      reactionTimeMs: rt,
      tapPressure: pressure,
      tapPosition: pos,
      eventType: 'tap_hit',
      gameContext: {'bubble_age_ms': rt, 'wave': _wave},
    );
    setState(() {
      bubble.popped = true;
      _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Score & wave
        Positioned(
          top: AppTheme.sm,
          left: AppTheme.md,
          right: AppTheme.md,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wave $_wave', style: AppTheme.headlineMed),
              Text('$_score popped', style: AppTheme.bodyMedium),
              Text('$_misses / $_maxMisses missed',
                  style: AppTheme.bodySmall),
            ],
          ),
        ),
        // Bubbles
        ...List.generate(_bubbles.length, (i) {
          final b = _bubbles[i];
          if (b.popped) return const SizedBox.shrink();
          return Positioned(
            left: b.x - b.radius,
            top: b.y - b.radius,
            child: Listener(
              onPointerDown: (e) => _tapBubble(b, e.position, e.pressure),
              child: Container(
                width: b.radius * 2,
                height: b.radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryLight.withValues(alpha: 0.7),
                      AppTheme.primary.withValues(alpha: 0.4),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.primaryMuted.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
