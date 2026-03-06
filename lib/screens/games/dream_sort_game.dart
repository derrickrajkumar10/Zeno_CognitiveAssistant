import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class DreamSortGame extends StatelessWidget {
  const DreamSortGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'dream_sort',
      gameTitle: 'Dream Sort',
      xpReward: 35,
      gameBuilder: (controller) => _DreamSortPlay(controller: controller),
    );
  }
}

class _DreamSortPlay extends StatefulWidget {
  final GameWrapperState controller;
  const _DreamSortPlay({required this.controller});

  @override
  State<_DreamSortPlay> createState() => _DreamSortPlayState();
}

class _SortItem {
  final String label;
  final IconData icon;
  final bool goesLeft; // true = left category, false = right
  final DateTime shownAt;
  _SortItem({
    required this.label,
    required this.icon,
    required this.goesLeft,
    required this.shownAt,
  });
}

class _DreamSortPlayState extends State<_DreamSortPlay> {
  final _rng = Random();
  _SortItem? _current;
  int _index = 0;
  int _correct = 0;
  int _errors = 0;
  bool _inverted = false;
  bool _gameOver = false;
  String _leftLabel = 'Nature';
  String _rightLabel = 'Urban';
  Timer? _autoTimer;
  double _lastPointerPressure = 0.5;
  static const _totalItems = 30;
  static const _invertAt = 15;

  static const _natureItems = [
    (label: 'Tree', icon: Icons.park_rounded),
    (label: 'Flower', icon: Icons.local_florist_rounded),
    (label: 'Mountain', icon: Icons.terrain_rounded),
    (label: 'Sun', icon: Icons.wb_sunny_rounded),
    (label: 'Wave', icon: Icons.waves_rounded),
  ];
  static const _urbanItems = [
    (label: 'Building', icon: Icons.apartment_rounded),
    (label: 'Car', icon: Icons.directions_car_rounded),
    (label: 'Phone', icon: Icons.phone_android_rounded),
    (label: 'Clock', icon: Icons.schedule_rounded),
    (label: 'Light', icon: Icons.lightbulb_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _showNext();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _showNext() {
    if (_index >= _totalItems) {
      setState(() => _gameOver = true);
      final total = _correct + _errors;
      final pct = total > 0 ? (_correct / total * 100).round() : 0;
      widget.controller.endGame(score: pct, levelReached: _correct);
      return;
    }

    if (_index == _invertAt && !_inverted) {
      _inverted = true;
      final tmp = _leftLabel;
      _leftLabel = _rightLabel;
      _rightLabel = tmp;
    }

    final isNature = _rng.nextBool();
    final pool = isNature ? _natureItems : _urbanItems;
    final pick = pool[_rng.nextInt(pool.length)];

    // After inversion, nature goes right, urban goes left
    bool goesLeft;
    if (!_inverted) {
      goesLeft = isNature; // Nature = left
    } else {
      goesLeft = !isNature; // Inverted: Urban = left (now labeled Nature)
    }

    _current = _SortItem(
      label: pick.label,
      icon: pick.icon,
      goesLeft: goesLeft,
      shownAt: DateTime.now(),
    );
    _index++;
    widget.controller.markStimulus();
    setState(() {});

    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(seconds: 3), () {
      if (_current != null) {
        _errors++;
        widget.controller.recordTouch(
          reactionTimeMs: 3000,
          eventType: 'tap_miss',
          gameContext: {'reason': 'timeout', 'inverted': _inverted},
        );
        _showNext();
      }
    });
  }

  void _swipe(bool swipedLeft, double pressure) {
    if (_gameOver || _current == null) return;
    HapticFeedback.lightImpact();
    _autoTimer?.cancel();

    final item = _current!;
    final rt = DateTime.now().difference(item.shownAt).inMilliseconds;
    final isCorrect = swipedLeft == item.goesLeft;

    if (isCorrect) {
      _correct++;
    } else {
      _errors++;
    }

    widget.controller.recordTouch(
      reactionTimeMs: rt,
      tapPressure: pressure,
      eventType: isCorrect ? 'swipe' : 'tap_miss',
      gameContext: {
        'item_index': _index,
        'inverted': _inverted,
        'swiped_left': swipedLeft,
        'correct_side_left': item.goesLeft,
      },
    );

    _showNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.lg),
      child: Column(
        children: [
          if (_inverted)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md, vertical: AppTheme.xs),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
              ),
              child: Text('Categories swapped!',
                  style: AppTheme.caption.copyWith(color: AppTheme.warning)),
            ),
          const SizedBox(height: AppTheme.sm),
          // Category labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CategoryLabel(label: _leftLabel, icon: Icons.arrow_back_rounded),
              Text('$_correct / $_index', style: AppTheme.bodySmall),
              _CategoryLabel(
                  label: _rightLabel, icon: Icons.arrow_forward_rounded),
            ],
          ),
          const Spacer(),
          // Current item card
          if (_current != null)
            GestureDetector(
              onHorizontalDragStart: (_) {},
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() > 100) {
                  _swipe(velocity < 0, _lastPointerPressure);
                }
              },
              child: Listener(
                onPointerDown: (event) => _lastPointerPressure = event.pressure,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_current!.icon, size: 48, color: AppTheme.primary),
                      const SizedBox(height: AppTheme.sm),
                      Text(_current!.label, style: AppTheme.headlineMed),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTheme.md),
          Text('Swipe left or right to sort',
              style: AppTheme.bodySmall),
          const Spacer(),
          LinearProgressIndicator(
            value: _index / _totalItems,
            backgroundColor: AppTheme.surfaceGlassDim,
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: AppTheme.md),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.labelLarge),
      ],
    );
  }
}
