import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/cognipulse_engine.dart';
import 'package:zeno/theme/app_theme.dart';

void showScoreBreakdownSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: const ScoreBreakdownSheet(),
        ),
      ),
    ),
  );
}

/// "Why is my score X?" — every input, its weight and the arithmetic.
class ScoreBreakdownSheet extends ConsumerWidget {
  const ScoreBreakdownSheet({super.key});

  static String _weight(double weight) => weight.toStringAsFixed(2);

  /// e.g. "(90 × 0.15 + 60 × 0.10) ÷ 0.25 = 78"
  static String formula(CogniPulseBreakdown breakdown) {
    final used = breakdown.parts.where((p) => p.measured).toList();
    final terms = used.map((p) => '${p.value} × ${_weight(p.weight)}').join(' + ');
    final total = used.fold<double>(0, (sum, p) => sum + p.weight);
    return '($terms) ÷ ${_weight(total)} = ${breakdown.score}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(appStateProvider.select((s) => s.breakdown));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, AppTheme.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          Text('Why is my score ${breakdown.score}?', style: AppTheme.displaySmall),
          const SizedBox(height: AppTheme.sm),
          Text(
            breakdown.hasCheckInToday
                ? 'A weighted blend of the latest reading from each check-in you did today.'
                : 'No check-ins yet today, so CogniPulse is using '
                    '${breakdown.hasBaseline ? 'your onboarding baseline' : 'a neutral starting point'}. '
                    'Log your mood, type, scan or play to update it.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppTheme.lg),
          ...breakdown.parts.map((part) => _PartRow(part: part)),
          const SizedBox(height: AppTheme.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The maths', style: AppTheme.labelLarge),
                const SizedBox(height: 6),
                Text(formula(breakdown), style: AppTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            'Score = Σ(reading × weight) ÷ Σ(weights used). Weights follow the '
            'ZENO PRD: typing 35%, phone usage 30%, face scan 20%, mood 15%. '
            'Game play (15%) and the onboarding baseline (10%) are additions. '
            'Signals with no reading today are left out, and the others are '
            'scaled up to fill their share.',
            style: AppTheme.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            'A wellness indicator, not a medical measurement. Everything stays on this phone.',
            style: AppTheme.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final SignalContribution part;

  const _PartRow({required this.part});

  String _time(DateTime at) {
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = part.label == 'Phone usage';
    final String detail;
    if (isPhone) {
      detail = 'Not measured in this build';
    } else if (!part.measured) {
      detail = 'No reading today';
    } else if (part.at != null && part.label != 'Baseline questionnaire') {
      detail = 'Latest at ${_time(part.at!)}';
    } else {
      detail = part.label == 'Neutral start' ? 'Onboarding was skipped' : 'From onboarding';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sm),
      child: Opacity(
        opacity: part.measured ? 1 : 0.55,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.label, style: AppTheme.headlineMed),
                  Text(detail, style: AppTheme.caption),
                ],
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                part.value?.toString() ?? '—',
                textAlign: TextAlign.right,
                style: AppTheme.headlineMed,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                part.measured
                    ? '${(part.share * 100).round()}% of score'
                    : '${(part.weight * 100).round()}% weight',
                textAlign: TextAlign.right,
                style: AppTheme.caption.copyWith(
                  color: part.measured ? AppTheme.primary : AppTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
