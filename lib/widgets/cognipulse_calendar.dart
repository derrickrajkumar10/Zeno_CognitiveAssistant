import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/models/mochi_state.dart';

class CogniPulseCalendar extends StatefulWidget {
  const CogniPulseCalendar({super.key});

  @override
  State<CogniPulseCalendar> createState() => _CogniPulseCalendarState();
}

class _CogniPulseCalendarState extends State<CogniPulseCalendar> {
  final _random = Random(42); // fixed seed for mock consistency
  int? _selectedDay;

  // Generate mock past 30 days of scores
  late final List<int?> _scores;

  @override
  void initState() {
    super.initState();
    _scores = List.generate(30, (index) {
      // simulate missing data randomly
      if (_random.nextDouble() > 0.85) return null;

      // higher chance of good scores recently
      if (index >= 23) return 60 + _random.nextInt(35);
      return 30 + _random.nextInt(60);
    });
  }

  Color _getColorForScore(int? score) {
    if (score == null) return AppTheme.surfaceBorder;
    if (score >= 80) return AppTheme.mochiThriving;
    if (score >= 55) return AppTheme.mochiBalanced;
    if (score >= 30) return AppTheme.mochiDrifting;
    return AppTheme.mochiStruggling;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30-Day Heatmap', style: AppTheme.headlineMed),
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: AppTheme.lg),

          // Days Of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                      width: 28,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: AppTheme.labelSmall,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.sm),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final score = _scores[index];
              final isSelected = _selectedDay == index;
              final color = _getColorForScore(score);

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedDay = isSelected ? null : index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : color.withOpacity(score == null ? 0.3 : 0.6),
                    shape: BoxShape.circle,
                    boxShadow: isSelected && score != null
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.5), blurRadius: 8)
                          ]
                        : null,
                    border: isSelected
                        ? Border.all(
                            color: Colors.white.withOpacity(0.8), width: 2)
                        : null,
                  ),
                ).animate().scale(
                    delay: Duration(milliseconds: index * 10),
                    duration: 200.ms),
              );
            },
          ),

          // Details view (Hero-like expansion underneath)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _selectedDay != null
                ? _buildDayDetails(_selectedDay!)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(int index) {
    final score = _scores[index];
    final color = _getColorForScore(score);
    final daysAgo = 29 - index;
    final dateStr = daysAgo == 0
        ? 'Today'
        : (daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago');

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.lg),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              score != null ? '$score' : '--',
              style: AppTheme.headlineMed.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: AppTheme.labelLarge),
                Text(
                  score != null
                      ? MochiMoodStateX.fromScore(score).label
                      : 'No data recorded',
                  style: AppTheme.bodySmall
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}
