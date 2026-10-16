import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/typing_analyzer.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

/// In-app stand-in for the PRD's keyboard layer (35% of CogniPulse): the
/// user types one practice sentence and Mochi scores the timing.
class TypingCheckIn extends ConsumerStatefulWidget {
  static const sentences = [
    'Small steps every day can carry you a very long way.',
    'Mochi naps under the maple tree while the river hums.',
    'A quiet walk helps a busy mind settle down again.',
    'Take one slow breath and let your shoulders drop.',
  ];

  /// Fixes the first sentence (tests); random when null.
  final int? sentenceIndex;

  const TypingCheckIn({super.key, this.sentenceIndex});

  @override
  ConsumerState<TypingCheckIn> createState() => _TypingCheckInState();
}

class _TypingCheckInState extends ConsumerState<TypingCheckIn> {
  final _controller = TextEditingController();
  final List<DateTime> _keystrokes = [];
  late int _sentenceIndex;
  int _backspaces = 0;
  String _previous = '';
  bool _pasteRejected = false;
  TypingResult? _result;

  String get _target => TypingCheckIn.sentences[_sentenceIndex];

  bool get _canFinish =>
      _controller.text.trim().length >= _target.length ~/ 2 && _keystrokes.length >= 2;

  @override
  void initState() {
    super.initState();
    _sentenceIndex =
        widget.sentenceIndex ?? Random().nextInt(TypingCheckIn.sentences.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final added = text.length - _previous.length;
    if (added > 3) {
      // A jump of several characters is a paste or autofill, not typing.
      _controller.clear();
      setState(() {
        _resetCounters();
        _pasteRejected = true;
      });
      return;
    }
    if (added < 0) {
      _backspaces += -added;
    }
    _keystrokes.add(DateTime.now());
    _previous = text;
    setState(() => _pasteRejected = false);
  }

  void _resetCounters() {
    _keystrokes.clear();
    _backspaces = 0;
    _previous = '';
  }

  Future<void> _finish() async {
    final result = TypingAnalyzer.analyze(
      target: _target,
      typed: _controller.text,
      keystrokes: _keystrokes,
      backspaces: _backspaces,
    );
    if (result == null) {
      return;
    }
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    await ref.read(appStateProvider.notifier).recordTypingCheckIn(
          score: result.score,
          stress: result.stress,
          note: result.note,
        );
    if (mounted) {
      setState(() => _result = result);
    }
  }

  void _restart() {
    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() {
      _resetCounters();
      _result = null;
      _pasteRejected = false;
      _sentenceIndex = (_sentenceIndex + 1) % TypingCheckIn.sentences.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return _TypingResultCard(result: result, onRestart: _restart);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Typing check-in', style: AppTheme.headlineMed),
          const SizedBox(height: 4),
          Text(
            'Type the sentence at your normal pace. Mochi looks at speed, '
            'corrections, pauses and accuracy on this sentence only.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
            ),
            child: Text(_target, style: AppTheme.bodyLarge),
          ),
          const SizedBox(height: AppTheme.md),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            autocorrect: false,
            enableSuggestions: false,
            enableInteractiveSelection: false,
            minLines: 2,
            maxLines: 3,
            style: AppTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Start typing…',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            _pasteRejected
                ? 'Mochi needs you to type it out, not paste it.'
                : '${_keystrokes.length} keystrokes · $_backspaces corrections',
            style: AppTheme.caption.copyWith(
              color: _pasteRejected ? AppTheme.error : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canFinish ? _finish : null,
              child: Text(
                'Finish check-in',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.textOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingResultCard extends StatelessWidget {
  final TypingResult result;
  final VoidCallback onRestart;

  const _TypingResultCard({required this.result, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppTheme.primarySoft.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Typing score',
                style: AppTheme.headlineMed.copyWith(color: AppTheme.primary),
              ),
              const Spacer(),
              Text(
                '${result.score}',
                style: AppTheme.displaySmall.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              _Pill(label: 'Speed', value: '${result.wpm.round()} wpm'),
              const SizedBox(width: AppTheme.sm),
              _Pill(label: 'Accuracy', value: '${(result.accuracy * 100).round()}%'),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              _Pill(
                label: 'Corrections',
                value: '${(result.correctionRate * 100).round()}%',
              ),
              const SizedBox(width: AppTheme.sm),
              _Pill(label: 'Long pauses', value: '${(result.pauseRatio * 100).round()}%'),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            'Score = 35% accuracy + 25% speed (40 wpm = full) + 25% fewer '
            'corrections + 15% fewer pauses over 1.5 s. It now feeds today\'s '
            'CogniPulse as the typing signal.',
            style: AppTheme.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppTheme.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRestart,
              child: Text('Try another sentence', style: AppTheme.labelLarge),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.headlineMed.copyWith(color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.caption.copyWith(color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}
