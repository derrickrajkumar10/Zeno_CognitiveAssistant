import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

/// Box breathing: inhale, hold, exhale, hold — one phase per [phaseDuration],
/// four phases per round. A session that runs all [rounds] is counted in app
/// state and reported through [onComplete]; stopping early counts nothing.
class QuickBreathingCard extends ConsumerStatefulWidget {
  final int rounds;
  final Duration phaseDuration;
  final VoidCallback? onComplete;

  const QuickBreathingCard({
    super.key,
    this.rounds = 4,
    this.phaseDuration = const Duration(seconds: 4),
    this.onComplete,
  });

  @override
  ConsumerState<QuickBreathingCard> createState() => _QuickBreathingCardState();
}

class _QuickBreathingCardState extends ConsumerState<QuickBreathingCard>
    with SingleTickerProviderStateMixin {
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  late final AnimationController _controller;
  Timer? _timer;
  bool _isActive = false;
  bool _finished = false;
  int _step = 0;

  int get _totalSteps => widget.rounds * _phases.length;
  String get _phase => _phases[_step % _phases.length];
  int get _round => _step ~/ _phases.length + 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.phaseDuration,
    );
  }

  void _startBreathing() {
    HapticFeedback.lightImpact();
    setState(() {
      _isActive = true;
      _finished = false;
      _step = 0;
    });
    _animatePhase();
    _timer?.cancel();
    _timer = Timer.periodic(widget.phaseDuration, (_) => _nextPhase());
  }

  void _nextPhase() {
    if (!mounted) {
      return;
    }
    if (_step + 1 >= _totalSteps) {
      _finish();
      return;
    }
    setState(() => _step++);
    _animatePhase();
  }

  void _animatePhase() {
    switch (_step % _phases.length) {
      case 0:
        _controller.forward(from: 0.0);
      case 2:
        _controller.reverse(from: 1.0);
    }
  }

  void _finish() {
    _timer?.cancel();
    _controller.value = 0.0;
    HapticFeedback.lightImpact();
    setState(() {
      _isActive = false;
      _finished = true;
      _step = 0;
    });
    ref.read(appStateProvider.notifier).recordBreathingSession();
    widget.onComplete?.call();
  }

  void _stopBreathing() {
    _timer?.cancel();
    _controller.stop();
    _controller.value = 0.0;
    setState(() {
      _isActive = false;
      _step = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.md),
        tint: _isActive ? AppTheme.primaryLight.withValues(alpha: 0.05) : null,
        child: _isActive ? _buildActiveState() : _buildInactiveState(),
      ),
    );
  }

  Widget _buildInactiveState() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.air_rounded, color: AppTheme.primaryLight),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _finished ? 'Nice work' : 'Take a moment',
                style: AppTheme.headlineMed,
              ),
              Text(
                _finished
                    ? '${widget.rounds} rounds done. Mochi breathed with you.'
                    : '${widget.rounds} rounds of box breathing',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _startBreathing,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
            foregroundColor: AppTheme.primaryLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(_finished ? 'Again' : 'Start'),
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Box Breathing', style: AppTheme.headlineMed),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppTheme.textSecondary,
              onPressed: _stopBreathing,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.xl),
        SizedBox(
          height: 120,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.6 + (_controller.value * 0.4);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppTheme.primaryLight.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _phase,
                      style: AppTheme.headlineMed.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        Text(
          'Round $_round of ${widget.rounds}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
