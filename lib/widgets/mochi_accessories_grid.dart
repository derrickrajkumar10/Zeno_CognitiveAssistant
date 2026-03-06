import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class MochiAccessoriesGrid extends StatefulWidget {
  final int totalQuestsCompleted;

  const MochiAccessoriesGrid({
    super.key,
    required this.totalQuestsCompleted,
  });

  @override
  State<MochiAccessoriesGrid> createState() => _MochiAccessoriesGridState();
}

class _MochiAccessoriesGridState extends State<MochiAccessoriesGrid> {
  // Mock accessory data (requires 5, 10, 25, 50, 100 quests)
  final List<Map<String, dynamic>> _accessories = [
    {'id': 'acorn_hat', 'icon': '🌰', 'name': 'Acorn Hat', 'req': 5},
    {'id': 'leaf_scarf', 'icon': '🍃', 'name': 'Leaf Scarf', 'req': 10},
    {'id': 'star_pin', 'icon': '⭐', 'name': 'Star Pin', 'req': 25},
    {'id': 'flower_crown', 'icon': '🌸', 'name': 'Flower Crown', 'req': 50},
    {'id': 'golden_paw', 'icon': '🏆', 'name': 'Golden Paw', 'req': 100},
  ];

  String? _equippedAccessory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mochi\'s Backpack', style: AppTheme.headlineLarge),
            const SizedBox(width: AppTheme.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.totalQuestsCompleted} quests',
                style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: AppTheme.sm),
        Text(
          'Complete quests to unlock items for Mochi.',
          style: AppTheme.bodySmall,
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        const SizedBox(height: AppTheme.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppTheme.sm,
            crossAxisSpacing: AppTheme.sm,
            childAspectRatio: 0.85,
          ),
          itemCount: _accessories.length,
          itemBuilder: (context, index) {
            final item = _accessories[index];
            final req = item['req'] as int;
            final isUnlocked = widget.totalQuestsCompleted >= req;
            final isEquipped = _equippedAccessory == item['id'];

            return GestureDetector(
              onTap: isUnlocked
                  ? () {
                      setState(() {
                        _equippedAccessory = isEquipped ? null : item['id'];
                      });
                    }
                  : null,
              child: GlassCard(
                padding: EdgeInsets.zero,
                tint: isEquipped
                    ? AppTheme.primaryLight.withOpacity(0.1)
                    : (isUnlocked
                        ? AppTheme.surfaceGlass
                        : AppTheme.surfaceGlassDim.withOpacity(0.2)),
                child: Stack(
                  children: [
                    // Outer border for equipped
                    if (isEquipped)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.primaryLight.withOpacity(0.6),
                                width: 2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.cardRadius),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      ),

                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isUnlocked ? 1.0 : 0.3,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              scale: isEquipped ? 1.2 : 1.0,
                              child: Text(
                                isUnlocked ? item['icon'] as String : '🔒',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUnlocked
                                ? item['name'] as String
                                : 'Unlocks at $req',
                            textAlign: TextAlign.center,
                            style: AppTheme.labelSmall.copyWith(
                              color: isUnlocked
                                  ? (isEquipped
                                      ? AppTheme.primaryLight
                                      : AppTheme.textSecondary)
                                  : AppTheme.textTertiary,
                              fontWeight: isEquipped
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (200 + index * 100).ms)
                  .slideY(begin: 0.1),
            );
          },
        ),
      ],
    );
  }
}
