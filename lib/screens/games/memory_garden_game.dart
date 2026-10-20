import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class MemoryGardenGame extends StatelessWidget {
  const MemoryGardenGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'memory_garden',
      gameTitle: 'Memory Garden',
      xpReward: 35,
      gameBuilder: (controller) => _MemoryGardenPlay(controller: controller),
    );
  }
}

class _MemoryGardenPlay extends StatefulWidget {
  final GameWrapperState controller;

  const _MemoryGardenPlay({required this.controller});

  @override
  State<_MemoryGardenPlay> createState() => _MemoryGardenPlayState();
}

class _GardenObject {
  final Offset position;
  final IconData icon;
  bool found;

  _GardenObject({
    required this.position,
    required this.icon,
  }) : found = false;
}

class _MemoryGardenPlayState extends State<_MemoryGardenPlay> {
  final _random = Random();
  List<_GardenObject> _objects = [];
  bool _showing = true;
  bool _gameOver = false;
  int _round = 1;
  int _correctTaps = 0;
  int _totalTaps = 0;
  DateTime? _hiddenAt;

  static const _maxRounds = 5;
  static const _icons = [
    Icons.local_florist_rounded,
    Icons.park_rounded,
    Icons.eco_rounded,
    Icons.grass_rounded,
    Icons.spa_rounded,
    Icons.yard_rounded,
    Icons.energy_savings_leaf_rounded,
    Icons.forest_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final count = _round + 2;
    _objects = List.generate(count, (_) {
      return _GardenObject(
        position: Offset(
          0.1 + _random.nextDouble() * 0.8,
          0.1 + _random.nextDouble() * 0.8,
        ),
        icon: _icons[_random.nextInt(_icons.length)],
      );
    });

    _hiddenAt = null;
    setState(() => _showing = true);
    widget.controller.markStimulus();

    Timer(Duration(milliseconds: 1500 + count * 500), () {
      if (!mounted) {
        return;
      }
      _hiddenAt = DateTime.now();
      setState(() => _showing = false);
    });
  }

  void _tapAt(Offset localPosition, Size areaSize, PointerDownEvent event) {
    if (_showing || _gameOver) {
      return;
    }

    HapticFeedback.lightImpact();
    _totalTaps++;

    final normalized = Offset(
      localPosition.dx / areaSize.width,
      localPosition.dy / areaSize.height,
    );

    _GardenObject? closestObject;
    double closestDistance = double.infinity;

    for (final object in _objects) {
      if (object.found) {
        continue;
      }
      final distance = (object.position - normalized).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestObject = object;
      }
    }

    final hit = closestObject != null && closestDistance < 0.12;
    final hoverTimeMs = _hiddenAt == null
        ? 0
        : DateTime.now().difference(_hiddenAt!).inMilliseconds;

    widget.controller.recordTouch(
      reactionTimeMs: hoverTimeMs,
      tapPressure: event.pressure,
      tapPosition: event.position,
      eventType: hit ? 'tap_hit' : 'tap_miss',
      gameContext: {
        'round': _round,
        'spatial_accuracy': (1 - closestDistance).clamp(0.0, 1.0),
        'hover_time_ms': hoverTimeMs,
      },
    );

    if (hit) {
      closestObject.found = true;
      _correctTaps++;
    }

    if (_objects.every((object) => object.found)) {
      if (_round >= _maxRounds) {
        _gameOver = true;
        final score = (_correctTaps / max(1, _totalTaps) * 100).round();
        widget.controller.endGame(score: score, levelReached: _round);
      } else {
        _round++;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _startRound();
        });
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Round $_round / $_maxRounds', style: AppTheme.headlineMed),
              Text('$_correctTaps found', style: AppTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            _showing ? 'Remember the positions...' : 'Tap where they were!',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Listener(
                  onPointerDown: (event) =>
                      _tapAt(event.localPosition, size, event),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGlassLite,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: AppTheme.surfaceBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Stack(
                      children: _objects.map((object) {
                        final left = object.position.dx * size.width - 20;
                        final top = object.position.dy * size.height - 20;
                        final visible = _showing || object.found;
                        return Positioned(
                          left: left,
                          top: top,
                          child: AnimatedOpacity(
                            opacity: visible ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: object.found
                                    ? AppTheme.primarySoft
                                    : AppTheme.surfaceCard,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: object.found
                                      ? AppTheme.primaryLight
                                      : AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Icon(
                                object.icon,
                                size: 20,
                                color: object.found
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
