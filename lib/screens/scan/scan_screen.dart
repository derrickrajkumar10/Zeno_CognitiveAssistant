import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_widget.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  bool _scanning = false;
  bool _complete = false;
  int _countdown = 5;
  int? _newScore;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    HapticFeedback.mediumImpact();
    setState(() {
      _scanning = true;
      _complete = false;
      _countdown = 5;
    });
    _tickCountdown();
  }

  void _tickCountdown() {
    if (_countdown <= 0) {
      _completeScan();
      return;
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdown--);
      _tickCountdown();
    });
  }

  void _completeScan() {
    final score = 60 + Random().nextInt(30);
    ref.read(appStateProvider.notifier).updateCogniPulse(score);
    HapticFeedback.heavyImpact();
    setState(() {
      _scanning = false;
      _complete = true;
      _newScore = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: pad.top + AppTheme.lg,
        left: AppTheme.lg,
        right: AppTheme.lg,
        bottom: pad.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CogniPulse Scan', style: AppTheme.displayMedium)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1),
          const SizedBox(height: AppTheme.sm),
          Text(
            'Quick check-in with your mind',
            style: AppTheme.bodySmall,
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          const SizedBox(height: AppTheme.xxl),

          // ── Scan area ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                // Mochi watching
                if (!_scanning)
                  const MochiWidget(size: 120, interactive: false)
                      .animate()
                      .fadeIn(duration: 600.ms),

                if (_scanning) ...[
                  // Pulsing scan ring
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      final scale = 1.0 + (_pulseCtrl.value * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryLight.withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryLight
                                    .withOpacity(0.2 * (1 - _pulseCtrl.value)),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_countdown',
                            style: AppTheme.displayLarge.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.lg),
                  Text(
                    'Scanning...',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],

                if (_complete && _newScore != null) ...[
                  const SizedBox(height: AppTheme.lg),
                  // Score reveal
                  GlassCard(
                    tint: AppTheme.primarySoft.withOpacity(0.5),
                    child: Column(
                      children: [
                        Text(
                          'Scan Complete',
                          style: AppTheme.headlineMed.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.md),
                        Text(
                          '$_newScore',
                          style: AppTheme.displayLarge.copyWith(
                            fontSize: 56,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('CogniPulse Score', style: AppTheme.bodySmall),
                        const SizedBox(height: AppTheme.md),
                        Text(
                          MockData.scanCompleteDialogue[
                              DateTime.now().millisecond %
                                  MockData.scanCompleteDialogue.length],
                          style: AppTheme.bodyMedium.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTheme.xxl),

          // ── Start button ────────────────────────────────────────
          if (!_scanning)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _complete ? _startScan : _startScan,
                child: Text(
                  _complete ? 'Scan Again' : 'Begin Scan',
                  style: AppTheme.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1),
        ],
      ),
    );
  }
}
