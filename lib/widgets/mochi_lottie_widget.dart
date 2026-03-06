import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class MochiLottieWidget extends StatefulWidget {
  final double size;
  final bool showCrown;

  const MochiLottieWidget({
    super.key,
    this.size = 210,
    this.showCrown = false,
  });

  @override
  State<MochiLottieWidget> createState() => _MochiLottieWidgetState();
}

class _MochiLottieWidgetState extends State<MochiLottieWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  OverlayEntry? _leafOverlay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _removeLeafOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeLeafOverlay() {
    _leafOverlay?.remove();
    _leafOverlay = null;
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _controller.stop();
    _controller.forward(from: 0);
    _showLeafBurst();
  }

  void _showLeafBurst() {
    _removeLeafOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    final overlay = Overlay.of(context);
    _leafOverlay = OverlayEntry(
      builder: (_) => _LeafBurst(center: center, onDone: _removeLeafOverlay),
    );
    overlay.insert(_leafOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Lottie.asset(
              'assets/animations/mochi_dance.json',
              controller: _controller,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _controller.repeat();
              },
            ),
            if (widget.showCrown)
              Positioned(
                top: widget.size * 0.04,
                child: const Text('🌿', style: TextStyle(fontSize: 28)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Leaf burst overlay ───────────────────────────────────────────────────────

class _LeafBurst extends StatefulWidget {
  final Offset center;
  final VoidCallback onDone;
  const _LeafBurst({required this.center, required this.onDone});

  @override
  State<_LeafBurst> createState() => _LeafBurstState();
}

class _LeafBurstState extends State<_LeafBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static final _rng = Random();

  // 3 leaves at random angles
  late final List<double> _angles = List.generate(
    3,
    (_) => _rng.nextDouble() * 2 * pi,
  );
  late final List<double> _distances = List.generate(
    3,
    (_) => 60 + _rng.nextDouble() * 20, // 60–80 px
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Stack(
          children: List.generate(3, (i) {
            final dx = cos(_angles[i]) * _distances[i] * t;
            final dy = sin(_angles[i]) * _distances[i] * t;
            return Positioned(
              left: widget.center.dx + dx - 10,
              top: widget.center.dy + dy - 10,
              child: Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: const Text('🍃', style: TextStyle(fontSize: 18)),
              ),
            );
          }),
        );
      },
    );
  }
}
