import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/mochi_personality_provider.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';

/// Premium glassmorphism speech bubble with typing indicator and typewriter effect.
class MochiDialogueBubble extends ConsumerStatefulWidget {
  const MochiDialogueBubble({super.key});

  @override
  ConsumerState<MochiDialogueBubble> createState() =>
      _MochiDialogueBubbleState();
}

class _MochiDialogueBubbleState extends ConsumerState<MochiDialogueBubble>
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  String _targetText = '';
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
  }

  void _startTypewriter(String text) {
    if (text == _targetText) return;
    _targetText = text;
    _isTyping = true;
    _displayedText = '';
    _typeNextChar(0);
  }

  void _typeNextChar(int index) {
    if (!mounted || index >= _targetText.length) {
      if (mounted) setState(() => _isTyping = false);
      return;
    }
    setState(() {
      _displayedText = _targetText.substring(0, index + 1);
    });
    Future.delayed(const Duration(milliseconds: 25), () {
      _typeNextChar(index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final line = ref.watch(mochiCurrentDialogueProvider);
    final loading = ref.watch(mochiLoadingProvider);

    // Trigger typewriter when dialogue changes
    if (!loading && line != _targetText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTypewriter(line);
      });
    }

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: Container(
              key: ValueKey(loading ? 'loading' : line),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(
                  color: AppTheme.surfaceBorder,
                  width: 0.5,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: loading
                  ? const _TypingIndicator()
                  : Text(
                      _isTyping ? _displayedText : line,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iMessage-style bouncing dots typing indicator
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
          child: _BouncingDot(delay: i * 200),
        );
      }),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
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
      animation: _anim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, _anim.value),
          child: child,
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.textTertiary.withOpacity(0.6),
        ),
      ),
    );
  }
}
