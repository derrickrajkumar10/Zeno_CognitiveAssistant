import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/screens/onboarding/onboarding_pages.dart';
import 'package:zeno/theme/app_theme.dart';

/// The five baseline questions, in [BaselineResult] order (stress, sleep,
/// focus, mood, energy). Every scale runs 1–5 with 5 as the healthiest
/// answer, so the stress question asks how *rarely* the user feels stressed.
class _Question {
  final String text;
  final String low;
  final String high;
  const _Question(this.text, this.low, this.high);
}

const _questions = [
  _Question('How often have you felt stressed this week?', 'All the time', 'Hardly ever'),
  _Question('How have you been sleeping?', 'Badly', 'Really well'),
  _Question('How easy is it to focus right now?', 'Very hard', 'Easy'),
  _Question('How has your mood been?', 'Low', 'Great'),
  _Question('How is your energy?', 'Drained', 'Full'),
];

/// Onboarding page that asks five 1–5 questions. Mochi uses the answers as
/// the starting CogniPulse score until the user logs a real check-in.
class BaselinePage extends StatefulWidget {
  final ValueChanged<List<int>> onComplete;
  const BaselinePage({required this.onComplete, super.key});

  @override
  State<BaselinePage> createState() => _BaselinePageState();
}

class _BaselinePageState extends State<BaselinePage> {
  final _answers = List<int?>.filled(BaselineResult.questionCount, null);

  bool get _allAnswered => _answers.every((a) => a != null);

  void _select(int question, int value) {
    HapticFeedback.lightImpact();
    setState(() => _answers[question] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundOnboardingStats,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'How have you been lately?',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Five quick taps. Mochi starts your score from these until '
                'your first check-in.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _QuestionCard(
                    index: i,
                    question: _questions[i],
                    selected: _answers[i],
                    onSelect: (value) => _select(i, value),
                  )
                      .animate(delay: (i * 70).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.08, end: 0, duration: 350.ms),
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Continue >',
                onPressed: _allAnswered
                    ? () => widget.onComplete(
                        _answers.map((a) => a!).toList(growable: false))
                    : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _Question question;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final captionStyle = GoogleFonts.nunito(
      fontSize: 11,
      color: AppTheme.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var value = 1; value <= 5; value++) ...[
                if (value > 1) const SizedBox(width: 8),
                Expanded(
                  child: _AnswerChip(
                    key: ValueKey('baseline-$index-$value'),
                    value: value,
                    selected: selected == value,
                    onTap: () => onSelect(value),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(question.low, style: captionStyle),
              Text(question.high, style: captionStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerChip({
    required this.value,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.selectedGreen : AppTheme.selectedGreenTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$value',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
