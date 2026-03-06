import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/providers/mochi_personality_provider.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiDialogueBubble extends ConsumerStatefulWidget {
  const MochiDialogueBubble({super.key});

  @override
  ConsumerState<MochiDialogueBubble> createState() => _MochiDialogueBubbleState();
}

class _MochiDialogueBubbleState extends ConsumerState<MochiDialogueBubble> {
  String _displayedText = '';
  String _targetText = '';
  bool _isTyping = false;
  int _lastDialogueCycle = -1;

  void _startTypewriter(String text) {
    if (text == _targetText) {
      return;
    }
    _targetText = text;
    _isTyping = true;
    _displayedText = '';
    _typeNextChar(0);
  }

  void _typeNextChar(int index) {
    if (!mounted || index >= _targetText.length) {
      if (mounted) {
        setState(() => _isTyping = false);
      }
      return;
    }
    setState(() {
      _displayedText = _targetText.substring(0, index + 1);
    });
    Future.delayed(const Duration(milliseconds: 25), () {
      _typeNextChar(index + 1);
    });
  }

  Future<void> _refreshDialogue() async {
    ref.read(mochiLoadingProvider.notifier).state = true;
    final appState = ref.read(appStateProvider);
    final mood = ref.read(mochiMoodProvider);
    final service = ref.read(ollamaServiceProvider);

    final line = await service.getMochiDialogue(
      cogniPulseScore: appState.cogniPulseScore,
      moodState: mood,
      setOllamaStatus: ref.read(appStateProvider.notifier).setOllamaStatus,
    );

    if (!mounted) {
      return;
    }

    ref.read(mochiDialogueProvider.notifier).state = line;
    ref.read(mochiLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(mochiLoadingProvider);
    final fallbackLine = ref.watch(mochiCurrentDialogueProvider);
    final currentLine = ref.watch(mochiDialogueProvider);
    final line = currentLine.isEmpty ? fallbackLine : currentLine;
    final dialogueCycle =
        ref.watch(appStateProvider.select((state) => state.dialogueCycleCount));

    if (_lastDialogueCycle != dialogueCycle) {
      _lastDialogueCycle = dialogueCycle;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDialogue();
      });
    }

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
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
          child: _BouncingDot(delay: index * 200),
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

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.textTertiary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
