import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

/// Asks "Reset everything?" and, on yes, deletes all user data. Returns
/// true when the data was reset; the caller then routes to onboarding.
Future<bool> confirmAndResetAllData(BuildContext context, WidgetRef ref) async {
  HapticFeedback.lightImpact();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      title: Text('Reset everything?', style: AppTheme.headlineMed),
      content: Text(
        'This deletes your check-ins, scans, games, XP, badges and name '
        'from this phone, then starts onboarding again. It cannot be undone.',
        style: AppTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return false;
  }
  await ref.read(appStateProvider.notifier).resetAllData();
  return true;
}
