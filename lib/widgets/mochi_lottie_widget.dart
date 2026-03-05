import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.stop();
    _controller.forward(from: 0);
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
