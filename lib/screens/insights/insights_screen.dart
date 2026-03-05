import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readings = MockData.weekReadings;
    final balancedDays = readings.where((r) => r.score >= 55).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundInsights,
      body: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 30,
              right: 20,
              child: Transform.rotate(
                angle: 0.25,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('💡', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 16,
              child: Transform.rotate(
                angle: -0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('📊', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
            Positioned(
              bottom: 140,
              right: 24,
              child: Transform.rotate(
                angle: 0.35,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero stat
                  Text(
                    '$balancedDays balanced\ndays 🌿',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      color: AppTheme.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This week\'s overview',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Line chart
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFFD0E0F0),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                final i = value.toInt();
                                if (i < 0 || i >= days.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(days[i],
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11));
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: readings
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(),
                                    e.value.score.toDouble()))
                                .toList(),
                            isCurved: true,
                            color: AppTheme.selectedGreen,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.selectedGreen
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    "🐾 Mochi's Weekly Read",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You're sharpest between 9–11am this week. The stress spike on Monday resolved by Wednesday — your bounce-back time is improving.",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    '🌅 Peak Performance',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You're sharpest between 9–11am. Block that time for deep work.",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    '📱 Stress Pattern',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Late-night screen time is your biggest pattern this week. Try a 10pm cutoff.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut),
            ),
          ],
        ),
      ),
    );
  }
}
