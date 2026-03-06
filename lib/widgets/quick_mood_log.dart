import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class QuickMoodLog extends StatefulWidget {
  const QuickMoodLog({super.key});

  @override
  State<QuickMoodLog> createState() => _QuickMoodLogState();
}

class _QuickMoodLogState extends State<QuickMoodLog> {
  int _selectedIndex = -1;
  final List<String> _emojis = ['😫', '😔', '😐', '🙂', '🌟'];
  final List<String> _labels = [
    'Struggling',
    'Drifting',
    'Okay',
    'Balanced',
    'Thriving'
  ];

  Color _getColor(int index) {
    switch (index) {
      case 0:
        return AppTheme.mochiStruggling;
      case 1:
        return AppTheme.mochiDrifting;
      case 2:
        return AppTheme.textSecondary;
      case 3:
        return AppTheme.mochiBalanced;
      case 4:
        return AppTheme.mochiThriving;
      default:
        return AppTheme.surfaceGlass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.md),
      tint: _selectedIndex != -1
          ? _getColor(_selectedIndex).withOpacity(0.05)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How are you feeling?',
                style: AppTheme.headlineMed,
              ),
              if (_selectedIndex != -1)
                Text(
                  _labels[_selectedIndex],
                  style: AppTheme.labelSmall.copyWith(
                    color: _getColor(_selectedIndex),
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_emojis.length, (index) {
              final isSelected = index == _selectedIndex;
              final isDimmed = _selectedIndex != -1 && !isSelected;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  // In a real app we'd update the provider here
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _getColor(index).withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? _getColor(index).withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.4 : (isDimmed ? 0.8 : 1.1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isDimmed ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
