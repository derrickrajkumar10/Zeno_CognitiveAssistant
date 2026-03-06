import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

/// Tasteful floating particle overlay for thriving mood.
/// Can be used standalone (no child required) as a transparent layer.
class ParticleOverlay extends ConsumerStatefulWidget {
  final Widget? child;
  const ParticleOverlay({this.child, super.key});

  @override
  ConsumerState<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends ConsumerState<ParticleOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(_updateParticles)
          ..repeat();
    _spawnParticles();
  }

  void _spawnParticles() {
    _particles.clear();
    for (int i = 0; i < 8; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 2.5 + _rng.nextDouble() * 3,
        speed: 0.1 + _rng.nextDouble() * 0.2,
        offset: _rng.nextDouble(),
        color: [
          AppTheme.mochiThriving,
          AppTheme.warningAmber,
          AppTheme.successMint,
        ][_rng.nextInt(3)],
      ));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.y -= p.speed * 0.002;
      p.opacity = (0.5 - ((_ctrl.value + p.offset) % 1.0)).clamp(0, 0.5);
      if (p.y < -0.1) p.y = 1.0 + _rng.nextDouble() * 0.2;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(mochiMoodProvider);
    final particleLayer = Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _ParticlePainter(List.from(_particles)),
          ),
        ),
      ),
    );

    if (mood != MochiMoodState.thriving) {
      return widget.child ?? const SizedBox.shrink();
    }

    if (widget.child != null) {
      return Stack(children: [widget.child!, particleLayer]);
    }

    // Standalone mode — just the particles, transparent
    return particleLayer;
  }
}

class _Particle {
  double x, y, size, speed, offset, opacity;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
    required this.color,
  }) : opacity = 0.3;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  const _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
