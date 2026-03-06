import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class FocusFlickerGame extends StatelessWidget {
  const FocusFlickerGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'focus_flicker',
      gameTitle: 'Focus Flicker',
      xpReward: 45,
      gameBuilder: (controller) => _FocusFlickerPlay(controller: controller),
    );
  }
}

class _FocusFlickerPlay extends StatefulWidget {
  final GameWrapperState controller;
  const _FocusFlickerPlay({required this.controller});

  @override
  State<_FocusFlickerPlay> createState() => _FocusFlickerPlayState();
}

enum _ItemCategory { fruit, animal, shape }

class _FlickerItem {
  final _ItemCategory category;
  final IconData icon;
  final String label;
  final DateTime shownAt;
  _FlickerItem({
    required this.category,
    required this.icon,
    required this.label,
    required this.shownAt,
  });
}

class _FocusFlickerPlayState extends State<_FocusFlickerPlay> {
  final _rng = Random();
  _FlickerItem? _currentItem;
  _ItemCategory _targetCategory = _ItemCategory.fruit;
  bool _ruleFlipped = false;
  int _itemIndex = 0;
  int _correct = 0;
  int _incorrect = 0;
  int _missed = 0;
  bool _gameOver = false;
  bool _showFeedback = false;
  bool _feedbackCorrect = false;
  Timer? _itemTimer;
  static const _totalItems = 30;
  static const _flipAt = 15;

  static const _items = <_ItemCategory, List<({IconData icon, String label})>>{
    _ItemCategory.fruit: [
      (icon: Icons.apple_rounded, label: 'Apple'),
      (icon: Icons.lunch_dining_rounded, label: 'Orange'),
      (icon: Icons.egg_rounded, label: 'Lemon'),
    ],
    _ItemCategory.animal: [
      (icon: Icons.pets_rounded, label: 'Cat'),
      (icon: Icons.cruelty_free_rounded, label: 'Bunny'),
      (icon: Icons.bug_report_rounded, label: 'Bug'),
    ],
    _ItemCategory.shape: [
      (icon: Icons.hexagon_rounded, label: 'Hexagon'),
      (icon: Icons.circle_rounded, label: 'Circle'),
      (icon: Icons.square_rounded, label: 'Square'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _showNextItem();
  }

  @override
  void dispose() {
    _itemTimer?.cancel();
    super.dispose();
  }

  int get _currentQuartile {
    final normalizedIndex = (_itemIndex / _totalItems).clamp(0.0, 0.999);
    return (normalizedIndex * 4).floor() + 1;
  }

  void _showNextItem() {
    if (_itemIndex >= _totalItems) {
      setState(() => _gameOver = true);
      final total = _correct + _incorrect + _missed;
      final pct = total > 0 ? (_correct / total * 100).round() : 0;
      widget.controller.endGame(score: pct, levelReached: _correct);
      return;
    }

    // Flip rule mid-session
    if (_itemIndex == _flipAt && !_ruleFlipped) {
      _ruleFlipped = true;
      // Switch target: fruit -> animal, animal -> shape, shape -> fruit
      _targetCategory = _ItemCategory
          .values[(_targetCategory.index + 1) % _ItemCategory.values.length];
    }

    // Pick random category and item
    final category =
        _ItemCategory.values[_rng.nextInt(_ItemCategory.values.length)];
    final pool = _items[category]!;
    final pick = pool[_rng.nextInt(pool.length)];

    _currentItem = _FlickerItem(
      category: category,
      icon: pick.icon,
      label: pick.label,
      shownAt: DateTime.now(),
    );
    _itemIndex++;
    widget.controller.markStimulus();
    setState(() {});

    // Auto-advance after 2 seconds if no tap
    _itemTimer?.cancel();
    _itemTimer = Timer(const Duration(seconds: 2), () {
      if (_currentItem != null) {
        final wasTarget = _currentItem!.category == _targetCategory;
        if (wasTarget) _missed++;
        widget.controller.recordTouch(
          reactionTimeMs: 2000,
          eventType: 'tap_miss',
          gameContext: {
            'reason': 'timeout',
            'was_target': wasTarget,
            'quartile': _currentQuartile,
            'rule_flipped': _ruleFlipped,
          },
        );
        _showNextItem();
      }
    });
  }

  void _onTap(double pressure) {
    if (_gameOver || _currentItem == null) return;
    HapticFeedback.lightImpact();
    _itemTimer?.cancel();

    final item = _currentItem!;
    final rt = DateTime.now().difference(item.shownAt).inMilliseconds;
    final isTarget = item.category == _targetCategory;

    if (isTarget) {
      _correct++;
      _feedbackCorrect = true;
    } else {
      _incorrect++;
      _feedbackCorrect = false;
    }

    widget.controller.recordTouch(
      reactionTimeMs: rt,
      tapPressure: pressure,
      eventType: isTarget ? 'tap_hit' : 'tap_miss',
      gameContext: {
        'item_index': _itemIndex,
        'quartile': _currentQuartile,
        'rule_flipped': _ruleFlipped,
        'category': item.category.name,
        'target': _targetCategory.name,
      },
    );

    setState(() => _showFeedback = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showFeedback = false);
        _showNextItem();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _onTap(e.pressure),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          children: [
            // Rule indicator
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md, vertical: AppTheme.sm),
              decoration: BoxDecoration(
                color: _ruleFlipped
                    ? AppTheme.warning.withValues(alpha: 0.15)
                    : AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
              ),
              child: Text(
                'Tap only: ${_targetCategory.name.toUpperCase()}',
                style: AppTheme.labelLarge.copyWith(
                  color: _ruleFlipped ? AppTheme.warning : AppTheme.primary,
                ),
              ),
            ),
            if (_ruleFlipped)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.xs),
                child: Text('Rule changed!',
                    style: AppTheme.caption.copyWith(color: AppTheme.warning)),
              ),
            const SizedBox(height: AppTheme.sm),
            Text('$_correct / $_itemIndex',
                style: AppTheme.bodySmall),
            const Spacer(),
            // Current item
            if (_currentItem != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _showFeedback
                      ? (_feedbackCorrect
                          ? AppTheme.success.withValues(alpha: 0.2)
                          : AppTheme.error.withValues(alpha: 0.2))
                      : AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_currentItem!.icon, size: 48, color: AppTheme.textPrimary),
                    const SizedBox(height: AppTheme.xs),
                    Text(_currentItem!.label, style: AppTheme.caption),
                  ],
                ),
              ),
            const Spacer(),
            // Progress
            LinearProgressIndicator(
              value: _itemIndex / _totalItems,
              backgroundColor: AppTheme.surfaceGlassDim,
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppTheme.md),
          ],
        ),
      ),
    );
  }
}
