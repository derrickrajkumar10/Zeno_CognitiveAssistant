import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/providers/mochi_personality_provider.dart';
import 'package:zeno/services/cognipulse_engine.dart';
import 'package:zeno/services/insight_engine.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/insight_correlation_card.dart';

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _shortDay(DateTime day) => _shortWeekdays[day.weekday - 1];

String _dayAndTime(DateTime at) =>
    '${_shortDay(at)} ${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';

/// 'bubble_drift' → 'Bubble Drift'.
String _gameTitle(String? gameId) {
  if (gameId == null || gameId.isEmpty) {
    return 'Game';
  }
  return gameId
      .split('_')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final week = state.weekDays;
    final withData = week.where((day) => day.hasData).toList();
    final latestFaceScan = state.latestFaceScan;
    final personality = ref.watch(mochiPersonalityProvider);
    final insights = InsightEngine.build(state.signals, state.baseline, state.asOf);
    final pad = MediaQuery.of(context).padding;

    final firstDay = week.first.day;
    final recent = state.signals
        .where((s) => !s.at.isBefore(firstDay))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final recentCheckIns =
        recent.where((s) => s.type != SignalType.game).take(6).toList();
    final recentGames =
        recent.where((s) => s.type == SignalType.game).take(5).toList();

    final avgScore = withData.isEmpty
        ? null
        : withData.map((day) => day.score!).reduce((a, b) => a + b) /
            withData.length;
    final bestDay = withData.isEmpty
        ? null
        : withData.reduce((a, b) => b.score! > a.score! ? b : a);

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
            'Your last 7 days',
            style: AppTheme.bodySmall,
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: AppTheme.lg),
          GlassCard(
            child: withData.isEmpty
                ? const _EmptyTrend()
                : _TrendChart(week: week),
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
                  value: avgScore == null ? '--' : avgScore.toStringAsFixed(0),
                  icon: Icons.insights_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatCard(
                  label: bestDay == null
                      ? 'Best Day'
                      : 'Best · ${_shortDay(bestDay.day)}',
                  value: bestDay == null ? '--' : '${bestDay.score}',
                  icon: Icons.star_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatCard(
                  label: 'Days Checked In',
                  value: withData.isEmpty
                      ? '--'
                      : '${withData.length} of ${week.length}',
                  icon: Icons.event_available_rounded,
                  color: AppTheme.info,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 350.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: AppTheme.lg),
          Text('Patterns', style: AppTheme.headlineMed),
          const SizedBox(height: AppTheme.sm),
          if (insights.isEmpty)
            GlassCard(
              child: Text(
                'Mochi will spot patterns after a few check-ins.',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
            )
          else
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.sm),
                  child: InsightCorrelationCard(
                    title: insight.title,
                    description: insight.description,
                    icon: _insightIcon(insight.kind),
                    gradientColors: _insightColors(insight.kind),
                  ),
                )),
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
          if (recentCheckIns.isNotEmpty) ...[
            _HistoryCard(
              title: 'Recent Check-ins',
              rows: recentCheckIns
                  .map((s) => _HistoryRow(
                        label: s.type.label,
                        when: _dayAndTime(s.at),
                        score: s.score,
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppTheme.lg),
          ],
          _HistoryCard(
            title: 'Recent Games',
            emptyText: 'No games finished this week.',
            rows: recentGames
                .map((s) => _HistoryRow(
                      label: _gameTitle(s.note),
                      when: _dayAndTime(s.at),
                      score: s.score,
                    ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.lg),
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

  static IconData _insightIcon(InsightKind kind) {
    switch (kind) {
      case InsightKind.trend:
        return Icons.trending_up_rounded;
      case InsightKind.bestDay:
        return Icons.star_rounded;
      case InsightKind.typingVsMood:
        return Icons.keyboard_rounded;
      case InsightKind.timeOfDay:
        return Icons.wb_twilight_rounded;
      case InsightKind.consistency:
        return Icons.event_available_rounded;
    }
  }

  static List<Color> _insightColors(InsightKind kind) {
    switch (kind) {
      case InsightKind.trend:
        return const [AppTheme.primaryLight, AppTheme.info];
      case InsightKind.bestDay:
        return const [AppTheme.accent, AppTheme.primaryLight];
      case InsightKind.typingVsMood:
        return const [AppTheme.error, AppTheme.accent];
      case InsightKind.timeOfDay:
        return const [AppTheme.info, AppTheme.primaryLight];
      case InsightKind.consistency:
        return const [AppTheme.primaryLight, AppTheme.accent];
    }
  }

  String _getWeeklySummary(MochiPersonality personality, double? avgScore) {
    if (avgScore == null) {
      return 'Mochi is still getting to know you, ${personality.userName}. Log your mood on Home or try a check-in in Scan, and this summary will fill in.';
    }
    if (avgScore >= 75) {
      return 'This was a strong week, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)}. Mochi is genuinely proud of the consistency.';
    } else if (avgScore >= 55) {
      return 'Steady week, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)} -- not flashy, but consistent. Mochi values that more than peaks.';
    } else {
      return 'This week was heavier than usual, ${personality.userName}. Your CogniPulse averaged ${avgScore.toStringAsFixed(0)}. Mochi sees you showing up though, and that matters.';
    }
  }
}

class _EmptyTrend extends StatelessWidget {
  const _EmptyTrend();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CogniPulse Trend', style: AppTheme.headlineMed),
        const SizedBox(height: AppTheme.lg),
        const Center(
          child: Icon(Icons.show_chart_rounded,
              size: 40, color: AppTheme.textTertiary),
        ),
        const SizedBox(height: AppTheme.sm),
        Center(child: Text('No check-ins yet', style: AppTheme.headlineMed)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Log your mood on Home or try a check-in in Scan.',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.md),
      ],
    );
  }
}

/// Score, stress and mood for each of the last seven days. Days without a
/// check-in are gaps in the lines, never zeros.
class _TrendChart extends StatelessWidget {
  final List<DaySummary> week;

  const _TrendChart({required this.week});

  LineChartBarData _line(double? Function(DaySummary) value, Color color,
      {bool fill = false}) {
    return LineChartBarData(
      spots: List.generate(week.length, (i) {
        final v = value(week[i]);
        return v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v);
      }),
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: color,
      barWidth: fill ? 3 : 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: fill ? 4 : 3,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: fill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CogniPulse Trend', style: AppTheme.headlineMed),
        const SizedBox(height: AppTheme.sm),
        const Wrap(
          spacing: AppTheme.md,
          children: [
            _LegendDot(label: 'Score', color: AppTheme.primaryLight),
            _LegendDot(label: 'Stress', color: AppTheme.error),
            _LegendDot(label: 'Mood', color: AppTheme.accent),
          ],
        ),
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
                      final index = value.toInt();
                      if (index < 0 || index >= week.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _shortDay(week[index].day),
                          style: AppTheme.labelSmall,
                        ),
                      );
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
              maxX: (week.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                _line((d) => d.stress, AppTheme.error),
                _line((d) => d.mood, AppTheme.accent),
                _line((d) => d.score?.toDouble(), AppTheme.primaryLight,
                    fill: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.labelSmall),
      ],
    );
  }
}

class _HistoryRow {
  final String label;
  final String when;
  final int score;

  const _HistoryRow({required this.label, required this.when, required this.score});
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final List<_HistoryRow> rows;
  final String? emptyText;

  const _HistoryCard({required this.title, required this.rows, this.emptyText});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headlineMed),
          const SizedBox(height: AppTheme.sm),
          if (rows.isEmpty && emptyText != null)
            Text(
              emptyText!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label, style: AppTheme.bodyMedium),
                          Text(row.when, style: AppTheme.labelSmall),
                        ],
                      ),
                    ),
                    Text(
                      '${row.score}',
                      style: AppTheme.headlineMed.copyWith(
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
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
