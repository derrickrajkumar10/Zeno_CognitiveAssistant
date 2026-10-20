import 'package:flutter/material.dart';
import 'package:zeno/theme/app_theme.dart';

/// What ZENO measures, what it does not, and where the data lives.
void showAboutZenoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AboutZenoSheet(),
  );
}

class _AboutZenoSheet extends StatelessWidget {
  const _AboutZenoSheet();

  static const _signals = [
    ('Mood check-in', 'You pick how you feel on Home.'),
    ('Typing check-in', 'Speed, accuracy, corrections and pauses on one sentence in Scan.'),
    ('Face scan', 'Smile, eye and head signals from Google ML Kit, run on the phone.'),
    ('Games', 'Reaction time and errors from the Playroom games.'),
    ('Phone usage', 'Not measured in this build.'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppTheme.lg),
          children: [
            Text('About ZENO', style: AppTheme.displaySmall),
            const SizedBox(height: AppTheme.sm),
            Text(
              'ZENO and Mochi turn a few quick check-ins into one CogniPulse '
              'score from 0 to 100. The breakdown on Home shows exactly how '
              'each score is worked out.',
              style: AppTheme.bodyMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppTheme.lg),
            Text('What goes into the score', style: AppTheme.headlineMed),
            const SizedBox(height: AppTheme.sm),
            for (final (title, detail) in _signals)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.bodyLarge),
                    Text(
                      detail,
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.md),
            Text('Your data', style: AppTheme.headlineMed),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Everything stays on this phone. Nothing is uploaded. Mochi\'s '
              'chat lines come from a local Ollama model when one is running '
              'on your network, and from built-in lines otherwise. You can '
              'erase everything with "Reset all data".',
              style: AppTheme.bodyMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              'ZENO is a wellness companion, not a medical device. It does not '
              'diagnose anything. If you are struggling, please talk to someone '
              'you trust or a professional.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
