import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/providers/mochi_personality_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final readings = state.weekDays.where((day) => day.hasData).toList();
    final latestFaceScan = state.latestFaceScan;
    final personality = ref.watch(mochiPersonalityProvider);
    final pad = MediaQuery.of(context).padding;

    final avgScore = readings.isEmpty
        ? 0.0
        : readings.map((reading) => reading.score!).reduce((a, b) => a + b) /
            readings.length;
    final bestDay = readings.isEmpty
        ? null
        : readings.reduce((a, b) => a.score! > b.score! ? a : b);
    final avgStress = readings.isEmpty
        ? 0.0
        : readings
                .map((reading) => reading.stress ?? 0)
                .reduce((a, b) => a + b) /
            readings.length;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: pad.top + AppTheme.lg,
        left: AppTheme.lg,
        right: AppTheme.lg,
        bottom: pad.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: AppTheme.displayMedium)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1),
          const SizedBox(height: AppTheme.sm),
          Text(
            'Your 7-day wellness overview',
            style: AppTheme.bodySmall,
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: AppTheme.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CogniPulse Trend', style: AppTheme.headlineMed),
                const SizedBox(height: AppTheme.md),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppTheme.surfaceBorder,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 20,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: AppTheme.labelSmall,
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              final index = value.toInt();
                              if (index >= 0 && index < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    days[index],
                                    style: AppTheme.labelSmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (readings.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            readings.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              readings[index].score!.toDouble(),
                            ),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppTheme.primaryLight,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.primaryLight,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryLight.withValues(alpha: 0.2),
                                AppTheme.primaryLight.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg Score',
                  value: avgScore.toStringAsFixed(0),
                  icon: Icons.insights_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatCard(
                  label: 'Best Day',
                  value: bestDay != null ? '${bestDay.score}' : '--',
                  icon: Icons.star_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatCard(
                  label: 'Avg Stress',
                  value: avgStress.toStringAsFixed(0),
                  icon: Icons.favorite_rounded,
                  color: AppTheme.error,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 350.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: AppTheme.lg),
          if (latestFaceScan != null) ...[
            GlassCard(
              tint: AppTheme.accentSoft.withValues(alpha: 0.45),
              child: _LatestFaceScanCard(scan: latestFaceScan),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 430.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: AppTheme.lg),
          ],
          GlassCard(
            tint: AppTheme.primarySoft.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 16,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Mochi\'s Take', style: AppTheme.headlineMed),
                  ],
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  _getWeeklySummary(personality, avgScore),
                  style: AppTheme.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 500.ms)
              .slideY(begin: 0.05),
        ],
      ),
    );
  }

  String _getWeeklySummary(MochiPersonality personality, double avgScore) {
    if (avgScore >= 75) {
      return 'This was a strong week, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)} and the trend is upward. Mochi is genuinely proud of the consistency.';
    } else if (avgScore >= 55) {
      return 'Steady week, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)} -- not flashy, but consistent. Mochi values that more than peaks.';
    } else {
      return 'This week was heavier than usual, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)}. Mochi sees you showing up though, and that matters.';
    }
  }
}

class _LatestFaceScanCard extends StatelessWidget {
  final FaceScanEntry scan;

  const _LatestFaceScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest Face Check-In', style: AppTheme.headlineMed),
        const SizedBox(height: AppTheme.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Smile',
                value: '${(scan.smileProbability * 100).round()}%',
                icon: Icons.sentiment_satisfied_alt_rounded,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: _StatCard(
                label: 'Eyes Open',
                value: '${(scan.eyeOpenAverage * 100).round()}%',
                icon: Icons.visibility_rounded,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: _StatCard(
                label: 'Coverage',
                value: '${(scan.faceCoverage * 100).round()}%',
                icon: Icons.center_focus_strong_rounded,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          scan.mochiInsight,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.displaySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }
}
