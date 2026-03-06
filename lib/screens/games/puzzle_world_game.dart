import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/theme/app_theme.dart';

class PuzzleWorldGame extends StatelessWidget {
  const PuzzleWorldGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameId: 'puzzle_world',
      gameTitle: "Mochi's Puzzle World",
      xpReward: 40,
      gameBuilder: (controller) => _PuzzleWorldPlay(controller: controller),
    );
  }
}

class _PuzzleWorldPlay extends StatefulWidget {
  final GameWrapperState controller;

  const _PuzzleWorldPlay({required this.controller});

  @override
  State<_PuzzleWorldPlay> createState() => _PuzzleWorldPlayState();
}

class _PuzzleWorldPlayState extends State<_PuzzleWorldPlay> {
  late List<int> _tiles;
  int _gridSize = 3;
  int _moves = 0;
  int _level = 1;
  int _wrongMoves = 0;
  int _lastWrongTile = -1;
  int _perseverationCount = 0;
  int _hintUses = 0;
  int _restartCount = 0;
  int _hintTileIndex = -1;
  bool _gameOver = false;
  DateTime? _levelStartAt;
  DateTime? _firstMoveAt;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel({bool isRestart = false}) {
    _gridSize = _level <= 2 ? 3 : 4;
    final count = _gridSize * _gridSize;
    _tiles = List.generate(count, (index) => index);
    _shuffle();
    _moves = 0;
    _wrongMoves = 0;
    _perseverationCount = 0;
    _lastWrongTile = -1;
    _hintTileIndex = -1;
    _levelStartAt = DateTime.now();
    _firstMoveAt = null;
    widget.controller.markStimulus();

    if (isRestart) {
      _restartCount++;
      widget.controller.recordTouch(
        eventType: 'tap_hit',
        gameContext: {
          'action': 'restart',
          'exclude_from_accuracy': true,
          'restart_count': _restartCount,
          'level': _level,
        },
      );
    }

    setState(() {});
  }

  void _shuffle() {
    final random = Random();
    for (int i = 0; i < 100 + _level * 20; i++) {
      final emptyIndex = _tiles.indexOf(0);
      final neighbors = _getNeighbors(emptyIndex);
      final pick = neighbors[random.nextInt(neighbors.length)];
      _tiles[emptyIndex] = _tiles[pick];
      _tiles[pick] = 0;
    }
  }

  List<int> _getNeighbors(int index) {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final neighbors = <int>[];
    if (row > 0) neighbors.add((row - 1) * _gridSize + col);
    if (row < _gridSize - 1) neighbors.add((row + 1) * _gridSize + col);
    if (col > 0) neighbors.add(row * _gridSize + col - 1);
    if (col < _gridSize - 1) neighbors.add(row * _gridSize + col + 1);
    return neighbors;
  }

  bool get _isSolved {
    for (int index = 0; index < _tiles.length; index++) {
      if (_tiles[index] != index) {
        return false;
      }
    }
    return true;
  }

  void _showHint() {
    final emptyIndex = _tiles.indexOf(0);
    final neighbors = _getNeighbors(emptyIndex);
    neighbors.sort((left, right) => _tiles[left].compareTo(_tiles[right]));
    _hintTileIndex = neighbors.isEmpty ? -1 : neighbors.first;
    _hintUses++;
    widget.controller.recordTouch(
      eventType: 'tap_hit',
      gameContext: {
        'action': 'hint',
        'exclude_from_accuracy': true,
        'hint_uses': _hintUses,
        'level': _level,
      },
    );
    setState(() {});
  }

  void _tapTile(int index, double pressure, Offset position) {
    if (_gameOver) {
      return;
    }

    final emptyIndex = _tiles.indexOf(0);
    final neighbors = _getNeighbors(emptyIndex);

    if (!neighbors.contains(index)) {
      _wrongMoves++;
      if (_tiles[index] == _lastWrongTile) {
        _perseverationCount++;
      }
      _lastWrongTile = _tiles[index];
      widget.controller.recordTouch(
        tapPressure: pressure,
        tapPosition: position,
        eventType: 'tap_miss',
        gameContext: {
          'perseveration_count': _perseverationCount,
          'level': _level,
          'hint_uses': _hintUses,
          'restart_count': _restartCount,
        },
      );
      return;
    }

    HapticFeedback.lightImpact();
    _moves++;
    _firstMoveAt ??= DateTime.now();
    final timeToFirstMoveMs = _levelStartAt == null || _firstMoveAt == null
        ? 0
        : _firstMoveAt!.difference(_levelStartAt!).inMilliseconds;

    widget.controller.recordTouch(
      tapPressure: pressure,
      tapPosition: position,
      eventType: 'tap_hit',
      gameContext: {
        'moves': _moves,
        'level': _level,
        'time_to_first_move_ms': timeToFirstMoveMs,
        'hint_uses': _hintUses,
        'restart_count': _restartCount,
      },
    );

    setState(() {
      _hintTileIndex = -1;
      _tiles[emptyIndex] = _tiles[index];
      _tiles[index] = 0;
    });

    if (_isSolved) {
      if (_level >= 5) {
        _gameOver = true;
        final score = (100 - _wrongMoves * 3 - _hintUses * 4 - _restartCount * 5)
            .clamp(0, 100);
        widget.controller.endGame(score: score, levelReached: _level);
      } else {
        _level++;
        Future.delayed(const Duration(milliseconds: 600), _startLevel);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Column(
        children: [
          Row(
            children: [
              Text('Level $_level', style: AppTheme.headlineMed),
              const Spacer(),
              Text('$_moves moves', style: AppTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_rounded, size: 18),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startLevel(isRestart: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Restart'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            'Hints: $_hintUses  •  Restarts: $_restartCount',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.md),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _tiles.length,
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    if (tile == 0) {
                      return const SizedBox.shrink();
                    }

                    final isCorrect = _tiles[index] == index;
                    final isHinted = index == _hintTileIndex;

                    return Listener(
                      onPointerDown: (event) =>
                          _tapTile(index, event.pressure, event.position),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.primarySoft
                              : AppTheme.surfaceCard,
                          borderRadius:
                              BorderRadius.circular(AppTheme.cardRadiusSm),
                          border: Border.all(
                            color: isHinted
                                ? AppTheme.accent
                                : isCorrect
                                    ? AppTheme.primaryLight
                                    : AppTheme.surfaceBorder,
                            width: isHinted ? 2 : 0.5,
                          ),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Center(
                          child: Text(
                            '$tile',
                            style: AppTheme.headlineLarge.copyWith(
                              color: isCorrect
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
