import 'dart:ui';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/weekly_letter.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user;
    final pad = MediaQuery.of(context).padding;

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
          // ── Header ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const MochiWidget(size: 100, interactive: false),
                const SizedBox(height: AppTheme.md),
                Text(user.name, style: AppTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'Level ${user.level}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: AppTheme.lg),

          // ── XP progress ─────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Experience', style: AppTheme.headlineMed),
                    Text(
                      '${user.xp} / ${user.xpToNextLevel} XP',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: user.xp / user.xpToNextLevel,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceGlassDim,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.primaryLight),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: AppTheme.md),

          // ── Stats grid ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${user.currentStreak}',
                  label: 'Streak',
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_rounded,
                  value: '${user.totalQuestsCompleted}',
                  label: 'Quests',
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _StatTile(
                  icon: Icons.insights_rounded,
                  value: user.avgCogniPulse?.toStringAsFixed(0) ?? '--',
                  label: 'Avg CP',
                  color: AppTheme.info,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 250.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: AppTheme.lg),

          // ── Badges ──────────────────────────────────────────────
          Text('Badges', style: AppTheme.headlineLarge)
              .animate()
              .fadeIn(duration: 500.ms, delay: 350.ms),
          const SizedBox(height: AppTheme.md),
          Wrap(
            spacing: AppTheme.sm,
            runSpacing: AppTheme.sm,
            children: user.badges.asMap().entries.map((e) {
              final badge = e.value;
              final idx = e.key;
              return GlassCard(
                tint: badge.unlocked
                    ? AppTheme.surfaceGlass
                    : AppTheme.surfaceGlassDim,
                borderRadius: AppTheme.cardRadiusSm,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: badge.unlocked ? 1.0 : 0.4,
                      child: Text(badge.icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        badge.name,
                        style: AppTheme.caption.copyWith(
                          color: badge.unlocked
                              ? AppTheme.textPrimary
                              : AppTheme.textTertiary,
                          fontWeight: badge.unlocked
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (!badge.unlocked) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${badge.current}/${badge.target}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (400 + idx * 60).ms);
            }).toList(),
          ),

          const SizedBox(height: AppTheme.lg),

          // ── Weekly Letter ───────────────────────────────────────
          GlassCard(
            onTap: () => _showWeeklyLetter(
              context,
              WeeklyLetter.write(
                name: user.name,
                signals: state.signals,
                baseline: state.baseline,
                xpEvents: state.xpEvents,
                now: state.asOf,
              ),
            ),
            tint: AppTheme.accentSoft.withOpacity(0.3),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mail_rounded,
                      color: AppTheme.accent, size: 22),
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mochi\'s Weekly Letter',
                          style: AppTheme.headlineMed),
                      Text('Tap to read', style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: AppTheme.lg),

          // ── Settings ────────────────────────────────────────────
          Text('Settings', style: AppTheme.headlineLarge)
              .animate()
              .fadeIn(duration: 500.ms, delay: 700.ms),
          const SizedBox(height: AppTheme.md),

          _SettingsTile(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
          ).animate().fadeIn(duration: 400.ms, delay: 750.ms),
          _SettingsTile(
            icon: Icons.palette_rounded,
            label: 'Appearance',
          ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
          _SettingsTile(
            icon: Icons.info_rounded,
            label: 'About ZENO',
          ).animate().fadeIn(duration: 400.ms, delay: 850.ms),
        ],
      ),
    );
  }

  void _showWeeklyLetter(BuildContext context, String letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.surfaceBorder, width: 0.5),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(AppTheme.lg),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.lg),
                  Text('Mochi\'s Letter', style: AppTheme.displaySmall),
                  const SizedBox(height: AppTheme.lg),
                  Text(
                    letter,
                    style: AppTheme.bodyLarge.copyWith(height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.displaySmall),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingsTile({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sm),
      child: GlassCard(
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: AppTheme.md),
            Text(label, style: AppTheme.bodyMedium),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
