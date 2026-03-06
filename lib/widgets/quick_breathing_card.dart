import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class QuickBreathingCard extends StatefulWidget {
  const QuickBreathingCard({super.key});

  @override
  State<QuickBreathingCard> createState() => _QuickBreathingCardState();
}

class _QuickBreathingCardState extends State<QuickBreathingCard>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  late final AnimationController _controller;
  String _phase = 'Inhale';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds per phase
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_phase == 'Inhale') {
            _phase = 'Hold';
          } else if (_phase == 'Hold' && _controller.value == 1.0) {
            _phase = 'Exhale';
            _controller.reverse();
          } // Wait, this logic needs tweaking
        });
      }
    });
  }

  void _startBreathing() async {
    setState(() => _isActive = true);
    // Simple 4-7-8 or Box breathing cycle logic
    while (_isActive && mounted) {
      if (!mounted) break;
      setState(() => _phase = 'Inhale');
      await _controller.forward(from: 0.0);
      if (!mounted) break;

      setState(() => _phase = 'Hold');
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) break;

      setState(() => _phase = 'Exhale');
      await _controller.reverse(from: 1.0);
      if (!mounted) break;

      setState(() => _phase = 'Hold');
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  void _stopBreathing() {
    setState(() {
      _isActive = false;
      _phase = 'Inhale';
    });
    _controller.stop();
    _controller.value = 0.0;
  }

  @override
  void dispose() {
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
        tint: _isActive ? AppTheme.primaryLight.withOpacity(0.05) : null,
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
            color: AppTheme.primaryLight.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.air_rounded, color: AppTheme.primaryLight),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Take a moment', style: AppTheme.headlineMed),
              Text('1-minute box breathing', style: AppTheme.bodySmall),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _startBreathing,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight.withOpacity(0.15),
            foregroundColor: AppTheme.primaryLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Start'),
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
                // Scale from 0.5 to 1.0 based on controller value
                final scale = 0.6 + (_controller.value * 0.4);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight.withOpacity(0.2),
                      border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.5),
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
          'Follow the animation',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
