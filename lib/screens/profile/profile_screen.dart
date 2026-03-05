import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/user_profile.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final xpProgress = user.xp / user.xpToNextLevel;

    return Scaffold(
      backgroundColor: AppTheme.backgroundProfile,
      body: SafeArea(
        child: Stack(
          children: [
            // Floating decoratives
            Positioned(
              top: 30,
              right: 20,
              child: Transform.rotate(
                angle: 0.2,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('⭐', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            Positioned(
              top: 140,
              left: 16,
              child: Transform.rotate(
                angle: -0.3,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🌿', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
            Positioned(
              bottom: 180,
              right: 24,
              child: Transform.rotate(
                angle: 0.35,
                child: const Opacity(
                  opacity: 0.6,
                  child: Text('🏆', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero name
                  Text(
                    user.name,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      color: AppTheme.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.selectedGreenTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Level ${user.level} · ${user.xp} / ${user.xpToNextLevel} XP',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.selectedGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // XP bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: xpProgress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        backgroundColor: const Color(0xFFE0D8F0),
                        valueColor: const AlwaysStoppedAnimation(
                            AppTheme.selectedGreen),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${user.xpToNextLevel - user.xp} XP to Level ${user.level + 1}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stats row
                  Row(children: [
                    _StatPill(
                        label: 'Quests',
                        value: '${user.totalQuestsCompleted}',
                        emoji: '⚡'),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Streak',
                        value: '${user.currentStreak}d',
                        emoji: '🔥'),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Avg',
                        value: user.avgCogniPulse.toStringAsFixed(0),
                        emoji: '📊'),
                  ]),
                  const SizedBox(height: 28),

                  // Weekly letter
                  GestureDetector(
                    onTap: () => _showWeeklyLetter(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.selectedGreenTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.selectedGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Text('🐾', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "This week's letter from Mochi",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Tap to read',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppTheme.selectedGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Badges
                  Text(
                    'Badges',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: user.badges.length,
                    itemBuilder: (_, i) => _BadgeCard(badge: user.badges[i]),
                  ),
                  const SizedBox(height: 28),

                  // Settings
                  Text(
                    'Settings',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsRow(
                      emoji: '🔒',
                      label: 'Privacy',
                      onTap: () => _comingSoon(context)),
                  _SettingsRow(
                      emoji: '🔔',
                      label: 'Notifications',
                      onTap: () => _comingSoon(context)),
                  _SettingsRow(
                      emoji: 'ℹ️',
                      label: 'About ZENO',
                      onTap: () => _comingSoon(context)),
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

  void _showWeeklyLetter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(controller: ctrl, children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0CDE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'A letter from Mochi 🐾',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              MockData.currentWeeklyLetter,
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                height: 1.8,
                color: AppTheme.textPrimary,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon'),
        backgroundColor: AppTheme.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value, emoji;
  const _StatPill(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badge.unlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Text(badge.icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.name,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badge.unlocked
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!badge.unlocked)
                Row(children: [
                  const Icon(Icons.lock_rounded,
                      size: 9, color: AppTheme.textSecondary),
                  const SizedBox(width: 2),
                  Text('Locked',
                      style: GoogleFonts.nunito(
                          fontSize: 9, color: AppTheme.textSecondary)),
                ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _SettingsRow(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary))),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}
