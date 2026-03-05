import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/mochi_dialogue_bubble.dart';
import 'package:zeno/widgets/mochi_lottie_widget.dart';
import 'package:zeno/widgets/particle_overlay.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = ref.watch(isOllamaLiveProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundHome,
      floatingActionButton: _DebugFab(isLive: isLive),
      body: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 40,
              left: 20,
              child: Transform.rotate(
                angle: -0.3,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 24,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('✨', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: 30,
              child: Transform.rotate(
                angle: 0.4,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🍃', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: 16,
              child: Transform.rotate(
                angle: -0.15,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌱', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Hero heading
                  Text(
                    'How are you\nfeeling?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 44,
                      color: AppTheme.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mochi + dialogue
                  const Center(
                    child: Hero(
                      tag: 'mochi-hero',
                      child: ParticleOverlay(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 280,
                              child: MochiDialogueBubble(),
                            ),
                            SizedBox(height: 12),
                            MochiLottieWidget(size: 220),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => HapticFeedback.lightImpact(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Check in 🌿',
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

class _DebugFab extends StatelessWidget {
  final bool isLive;
  const _DebugFab({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: null,
      backgroundColor: AppTheme.cardSurface.withValues(alpha: 0.9),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isLive ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 12,
          color: isLive ? AppTheme.successMint : AppTheme.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          isLive ? 'LIVE' : 'MOCK',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: isLive ? AppTheme.successMint : AppTheme.textSecondary,
          ),
        ),
      ]),
    );
  }
}
