import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single floating leaf that drifts upward/sideways with a sine-wave wobble.
/// Wrap multiple in a [Stack] with random positions for a forest-particle effect.
class LeafParticle extends StatefulWidget {
  final String emoji;
  final double size;
  final Duration delay;
  final Duration duration;
  final double driftX; // total horizontal drift in logical pixels

  const LeafParticle({
    super.key,
    this.emoji = '🍃',
    this.size = 18,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 2400),
    this.driftX = 30,
  });

  @override
  State<LeafParticle> createState() => _LeafParticleState();
}

class _LeafParticleState extends State<LeafParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        final dx = math.sin(t * math.pi * 2.5) * widget.driftX * 0.5
            + t * widget.driftX;
        final dy = -t * 120; // drift upward
        final opacity = t < 0.15
            ? t / 0.15
            : t > 0.75
                ? (1 - t) / 0.25
                : 1.0;
        final rotate = math.sin(t * math.pi * 3) * 0.4;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: rotate,
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: widget.size),
              ),
            ),
          ),
        );
      },
    );
  }
}
