import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/mochi_lottie_widget.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _scanning = false;
  bool _scanComplete = false;
  int _countdown = 5;

  Future<void> _startScan() async {
    HapticFeedback.lightImpact();
    setState(() {
      _scanning = true;
      _scanComplete = false;
      _countdown = 5;
    });
    for (int i = 4; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i);
    }
    if (mounted) {
      setState(() {
        _scanning = false;
        _scanComplete = true;
      });
      _updateScore();
    }
  }

  void _updateScore() {
    HapticFeedback.lightImpact();
    final newScore = 73 + Random().nextInt(10) - 5;
    ref.read(appStateProvider.notifier).updateCogniPulse(newScore);
    ref.read(mochiDialogueProvider.notifier).state = MockData
        .scanCompleteDialogue[DateTime.now().millisecondsSinceEpoch %
            MockData.scanCompleteDialogue.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundScan,
      body: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 30,
              right: 24,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('✨', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 16,
              child: Transform.rotate(
                angle: -0.3,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🔍', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
            Positioned(
              bottom: 160,
              right: 20,
              child: Transform.rotate(
                angle: 0.4,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero heading
                  Text(
                    'Snap your\nmood 📸',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      color: AppTheme.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick scan to update your CogniPulse',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Camera viewport with Mochi peeking
                  Expanded(
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Scan viewport
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              color: _scanComplete
                                  ? AppTheme.selectedGreenTint
                                  : const Color(0xFFF0EAE0),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _scanComplete
                                    ? AppTheme.selectedGreen
                                    : const Color(0xFFE0D8D0),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: _scanComplete
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppTheme.successMint, size: 56),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Scan complete!',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Valence: 7.2 / 10 · Neutral-Positive',
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _scanning
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.face_outlined,
                                                color: AppTheme.textSecondary,
                                                size: 56),
                                            const SizedBox(height: 12),
                                            Text(
                                              _countdown > 0
                                                  ? 'Scanning… $_countdown'
                                                  : 'Processing…',
                                              style: GoogleFonts.nunito(
                                                fontSize: 18,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt_rounded,
                                                color: AppTheme.textSecondary
                                                    .withValues(alpha: 0.5),
                                                size: 64),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Tap below to start',
                                              style: GoogleFonts.nunito(
                                                fontSize: 16,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),

                          // Mochi peeking from bottom
                          const Positioned(
                            bottom: -30,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 70,
                                height: 40,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: 0.4,
                                    child: MochiLottieWidget(size: 100),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _scanning ? null : _startScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryButton,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryButton.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _scanComplete ? 'Scan again 📸' : 'Start scan 📸',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
