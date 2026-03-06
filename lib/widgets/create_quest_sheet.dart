import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class CreateCustomQuestSheet extends ConsumerStatefulWidget {
  const CreateCustomQuestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => const CreateCustomQuestSheet(),
    );
  }

  @override
  ConsumerState<CreateCustomQuestSheet> createState() =>
      _CreateCustomQuestSheetState();
}

class _CreateCustomQuestSheetState
    extends ConsumerState<CreateCustomQuestSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedDuration = '5 min';
  final _durations = ['Now', '5 min', '10 min', '15 min'];
  String _selectedIcon = '✨';
  final _icons = ['✨', '💧', '🏃', '🧘', '📖', '📵'];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;

    // Create custom quest (in real app, use provider to add to state)
    // For now, simply close sheet with success feel
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset + AppTheme.md : AppTheme.xxl,
          top: AppTheme.md,
          left: AppTheme.md,
          right: AppTheme.md,
        ),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cardRadiusLg)),
          border: const Border(top: BorderSide(color: AppTheme.surfaceBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.lg),

            Text(
              'Create Custom Quest',
              style: AppTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.md),

            GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md, vertical: 8),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: AppTheme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Do 10 pushups',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  icon:
                      Text(_selectedIcon, style: const TextStyle(fontSize: 24)),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),

            const SizedBox(height: AppTheme.md),

            // Icon Selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppTheme.sm),
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryLight.withOpacity(0.2)
                            : AppTheme.surfaceGlass,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryLight.withOpacity(0.5)
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.lg),

            // Duration selector
            Text('Duration', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.sm),
            Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: _durations.map((duration) {
                final isSelected = duration == _selectedDuration;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = duration),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.surfaceGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      duration,
                      style: AppTheme.bodySmall.copyWith(
                        color: isSelected
                            ? AppTheme.textOnPrimary
                            : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.xl),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Quest'),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}
