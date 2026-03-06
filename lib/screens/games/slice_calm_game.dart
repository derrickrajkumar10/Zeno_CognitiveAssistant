import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class SliceCalmGame extends StatelessWidget {
  const SliceCalmGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'slice_calm',
      gameTitle: 'Slice & Calm',
      xpReward: 30,
      gameBuilder: (controller) => _SliceCalmPlay(controller: controller),
    );
  }
}

class _SliceCalmPlay extends StatefulWidget {
  final GameWrapperState controller;
  const _SliceCalmPlay({required this.controller});

  @override
  State<_SliceCalmPlay> createState() => _SliceCalmPlayState();
}

class _Leaf {
  double x, y, speed, size;
  bool isGolden; // true = slice, false = stone (avoid)
  bool sliced;
  final DateTime spawnTime;
  _Leaf({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.isGolden,
    required this.spawnTime,
  }) : sliced = false;
}

class _SliceCalmPlayState extends State<_SliceCalmPlay>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final List<_Leaf> _leaves = [];
  late AnimationController _ticker;
  int _score = 0;
  int _falsePositives = 0;
  int _missed = 0;
  int _total = 0;
  int _spawned = 0;
  bool _gameOver = false;
  double _lastPointerPressure = 0.5;
  static const _maxSpawn = 40;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _ticker.repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update() {
    if (_gameOver) return;
    setState(() {
      for (final leaf in _leaves) {
        if (!leaf.sliced) {
          leaf.x += leaf.speed;
        }
      }
      // Count missed golden leaves that went off screen
      final offscreen = _leaves
          .where((l) => !l.sliced && (l.x > MediaQuery.of(context).size.width + 50))
          .toList();
      for (final l in offscreen) {
        if (l.isGolden) {
          _missed++;
          widget.controller.recordTouch(
            reactionTimeMs: DateTime.now().difference(l.spawnTime).inMilliseconds,
            tapPressure: 0,
            eventType: 'tap_miss',
            gameContext: {'reason': 'missed_golden_leaf'},
          );
        }
      }
      _leaves.removeWhere(
          (l) => l.sliced || l.x > MediaQuery.of(context).size.width + 50);

      // Spawn
      if (_spawned < _maxSpawn && _rng.nextDouble() < 0.04) {
        _spawnLeaf();
      }

      if (_spawned >= _maxSpawn && _leaves.isEmpty) {
        _gameOver = true;
        _total = _score + _missed + _falsePositives;
        final pct = _total > 0 ? (_score / max(1, _score + _missed) * 100).round() : 0;
        widget.controller.endGame(score: pct, levelReached: _score);
      }
    });
  }

  void _spawnLeaf() {
    final screenH = MediaQuery.of(context).size.height;
    _spawned++;
    final leaf = _Leaf(
      x: -40,
      y: 80 + _rng.nextDouble() * (screenH - 200),
      speed: 1.5 + _rng.nextDouble() * 2,
      size: 36 + _rng.nextDouble() * 16,
      isGolden: _rng.nextDouble() > 0.3, // 70% golden, 30% stone
      spawnTime: DateTime.now(),
    );
    _leaves.add(leaf);
    widget.controller.markStimulus();
  }

  void _swipeLeaf(_Leaf leaf, Offset pos, double pressure) {
    if (leaf.sliced || _gameOver) return;
    HapticFeedback.lightImpact();
    leaf.sliced = true;
    final rt = DateTime.now().difference(leaf.spawnTime).inMilliseconds;

    if (leaf.isGolden) {
      _score++;
      widget.controller.recordTouch(
        reactionTimeMs: rt,
        tapPressure: pressure,
        tapPosition: pos,
        eventType: 'swipe',
        gameContext: {'type': 'golden'},
      );
    } else {
      _falsePositives++;
      widget.controller.recordTouch(
        reactionTimeMs: rt,
        tapPressure: pressure,
        tapPosition: pos,
        eventType: 'tap_miss',
        gameContext: {'type': 'stone', 'false_positive': true},
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // HUD
        Positioned(
          top: AppTheme.sm,
          left: AppTheme.md,
          right: AppTheme.md,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_score sliced', style: AppTheme.headlineMed),
              Text('$_falsePositives stones hit',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            ],
          ),
        ),
        // Leaves
        ...List.generate(_leaves.length, (i) {
          final leaf = _leaves[i];
          if (leaf.sliced) return const SizedBox.shrink();
          return Positioned(
            left: leaf.x,
            top: leaf.y,
            child: Listener(
              onPointerDown: (event) => _lastPointerPressure = event.pressure,
              child: GestureDetector(
                onPanStart: (details) =>
                    _swipeLeaf(leaf, details.globalPosition, _lastPointerPressure),
                child: Container(
                  width: leaf.size,
                  height: leaf.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: leaf.isGolden
                        ? AppTheme.accent.withValues(alpha: 0.8)
                        : AppTheme.textTertiary.withValues(alpha: 0.5),
                    border: Border.all(
                      color:
                          leaf.isGolden ? AppTheme.accent : AppTheme.textSecondary,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    leaf.isGolden
                        ? Icons.eco_rounded
                        : Icons.hexagon_rounded,
                    size: leaf.size * 0.5,
                    color: leaf.isGolden
                        ? AppTheme.textOnPrimary
                        : AppTheme.textSecondary,
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
