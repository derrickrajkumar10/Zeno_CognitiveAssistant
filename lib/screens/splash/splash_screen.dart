import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    // Cinematic sequence duration:
    // 1. Bloom & logo (3s)
    // 2. Text fade in (1.5s)
    // 3. Complete fade out and navigate (1s)
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      final onboarded = ref.read(appStateProvider).onboardingComplete;
      context.go(onboarded ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Glow Boom ───────────────────────────────
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1.5, 1.5),
                    duration: 2500.ms,
                    curve: Curves.easeOutCubic)
                .fadeIn(duration: 1500.ms)
                .then(delay: 1500.ms)
                .fadeOut(duration: 1000.ms),
          ),

          // ── ZENO Logo & Text ────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Image
                Image.asset(
                  'assets/images/zeno_logo.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                    .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.0, 1.0),
                        duration: 2000.ms,
                        curve: Curves.easeOutCubic)
                    .then(delay: 2000.ms)
                    .fadeOut(duration: 800.ms),

                const SizedBox(height: AppTheme.md),

                // Subtitle
                Text(
                  'Your mind, your pace.',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1000.ms, delay: 1500.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 1000.ms,
                        curve: Curves.easeOut)
                    .then(delay: 700.ms)
                    .fadeOut(duration: 800.ms),
              ],
            ),
          ),

          // ── Floating Leaves (Particles) ─────────────────────────
          const Positioned.fill(
            child: _SplashParticles(),
          ),
        ],
      ).animate().fadeOut(
          delay: 3600.ms,
          duration: 400.ms), // Complete screen fade out at the end
    );
  }
}

class _SplashParticles extends StatefulWidget {
  const _SplashParticles();
  @override
  State<_SplashParticles> createState() => _SplashParticlesState();
}

class _SplashParticlesState extends State<_SplashParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addListener(() => setState(() {}))
          ..forward();

    for (int i = 0; i < 4; i++) {
      _particles.add(_Particle(
          x: 0.2 + (i * 0.2), y: 0.8 + (i * 0.1), speed: 0.4 + (i * 0.1)));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SplashParticlePainter(_particles, _ctrl.value),
      ),
    );
  }
}

class _Particle {
  double x, y, speed;
  _Particle({required this.x, required this.y, required this.speed});
}

class _SplashParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _SplashParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      final currentY = p.y - (progress * p.speed);
      canvas.drawCircle(
        Offset(p.x * size.width + (progress * 20 * (p.speed > 0.5 ? 1 : -1)),
            currentY * size.height),
        3.0 + (p.speed * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
