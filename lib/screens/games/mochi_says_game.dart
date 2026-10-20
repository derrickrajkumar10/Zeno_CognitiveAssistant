import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiSaysGame extends StatelessWidget {
  const MochiSaysGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'mochi_says',
      gameTitle: 'Mochi Says',
      xpReward: 40,
      gameBuilder: (controller) => _MochiSaysPlay(controller: controller),
    );
  }
}

class _MochiSaysPlay extends StatefulWidget {
  final GameWrapperState controller;

  const _MochiSaysPlay({required this.controller});

  @override
  State<_MochiSaysPlay> createState() => _MochiSaysPlayState();
}

class _MochiSaysPlayState extends State<_MochiSaysPlay> {
  final _random = Random();
  final List<int> _sequence = [];

  int _inputIndex = 0;
  int _round = 0;
  int _errors = 0;
  int _highlightedCell = -1;
  bool _showingSequence = false;
  bool _gameOver = false;
  DateTime? _lastErrorAt;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  void _nextRound() {
    _round++;
    _inputIndex = 0;
    _sequence.add(_random.nextInt(9));
    _showSequence();
  }

  Future<void> _showSequence() async {
    setState(() => _showingSequence = true);
    await Future.delayed(const Duration(milliseconds: 400));
    for (final cell in _sequence) {
      if (!mounted) return;
      setState(() => _highlightedCell = cell);
      await Future.delayed(Duration(milliseconds: max(300, 600 - _round * 30)));
      if (!mounted) return;
      setState(() => _highlightedCell = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;
    setState(() => _showingSequence = false);
    widget.controller.markStimulus();
  }

  void _tapCell(int index, PointerDownEvent event) {
    if (_showingSequence || _gameOver) {
      return;
    }

    HapticFeedback.lightImpact();
    final correct = _sequence[_inputIndex] == index;
    final reattemptLatencyMs = _lastErrorAt == null
        ? 0
        : DateTime.now().difference(_lastErrorAt!).inMilliseconds;

    widget.controller.recordTouch(
      tapPressure: event.pressure,
      tapPosition: event.position,
      eventType: correct ? 'tap_hit' : 'tap_miss',
      gameContext: {
        'sequence_index': _inputIndex,
        'sequence_length': _sequence.length,
        'error_stage':
            _inputIndex < (_sequence.length / 2) ? 'early' : 'late',
        'reattempt_latency_ms': reattemptLatencyMs,
      },
    );

    if (!correct) {
      _errors++;
      _lastErrorAt = DateTime.now();
      if (_errors >= 3) {
        _gameOver = true;
        final score = ((_round - 1) / max(1, _round) * 100).round();
        widget.controller.endGame(score: score, levelReached: _round);
        return;
      }

      setState(() => _highlightedCell = -2);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) {
          return;
        }
        setState(() => _highlightedCell = -1);
        _inputIndex = 0;
        _showSequence();
      });
      return;
    }

    setState(() => _highlightedCell = index);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _highlightedCell = -1);
      }
    });

    _inputIndex++;
    if (_inputIndex >= _sequence.length) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _nextRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.lg),
      child: Column(
        children: [
          Text('Round $_round', style: AppTheme.displaySmall),
          const SizedBox(height: AppTheme.sm),
          Text(
            _showingSequence ? 'Watch Mochi...' : 'Your turn!',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          Text('Errors: $_errors / 3', style: AppTheme.caption),
          const Spacer(),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppTheme.sm,
                crossAxisSpacing: AppTheme.sm,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isHighlighted = _highlightedCell == index;
                final isError = _highlightedCell == -2;
                return Listener(
                  onPointerDown: (event) => _tapCell(index, event),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isError
                          ? AppTheme.error.withValues(alpha: 0.3)
                          : isHighlighted
                              ? AppTheme.primary
                              : AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
                      border: Border.all(
                        color: isHighlighted
                            ? AppTheme.primaryLight
                            : AppTheme.surfaceBorder,
                        width: isHighlighted ? 2 : 0.5,
                      ),
                    ),
                    child: isHighlighted
                        ? const Center(
                            child: Icon(
                              Icons.pets_rounded,
                              color: AppTheme.textOnPrimary,
                              size: 32,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
