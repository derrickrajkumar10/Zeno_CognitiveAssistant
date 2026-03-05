import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class QuestCard extends ConsumerWidget {
  final Quest quest;
  final int index;
  const QuestCard({required this.quest, this.index = 0, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = quest.status == QuestStatus.completed;
    return AnimatedContainer(
      duration: 350.ms,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.cardSurface.withValues(alpha: 0.4)
            : AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4DDD4)),
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading: Text(quest.icon, style: const TextStyle(fontSize: 26))
                .animate(target: done ? 0.6 : 1.0)
                .fade(),
            title: Text(
              quest.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: done ? AppTheme.textSecondary : AppTheme.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                quest.duration,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            trailing: done
                ? const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successMint, size: 26)
                : GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(appStateProvider.notifier).completeQuest(quest.id);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '+${quest.xpReward} XP',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
          ),
          // XP burst overlay — shown briefly on completion
          if (done) _XpBurst(xp: quest.xpReward),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.25, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _XpBurst extends StatefulWidget {
  final int xp;
  const _XpBurst({required this.xp});
  @override
  State<_XpBurst> createState() => _XpBurstState();
}

class _XpBurstState extends State<_XpBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _rise = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _ctrl.forward().then((_) {
          if (mounted) setState(() => _visible = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      top: 8,
      child: SlideTransition(
        position: _rise,
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            '+${widget.xp} XP',
            style: const TextStyle(
              color: AppTheme.successMint,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
