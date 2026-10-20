import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/services/ollama_settings.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/ambient_background.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/reset_data_dialog.dart';

/// Hidden presenter tools, opened by long-pressing Mochi on Profile.
/// Everything here is either labelled in the app (the score override) or
/// writes real, tagged data (the demo week), so the demo never hides what
/// the app actually measured.
class DeveloperPanel extends ConsumerStatefulWidget {
  const DeveloperPanel({super.key});

  @override
  ConsumerState<DeveloperPanel> createState() => _DeveloperPanelState();
}

class _DeveloperPanelState extends ConsumerState<DeveloperPanel> {
  late final TextEditingController _hostController =
      TextEditingController(text: ref.read(ollamaHostProvider));
  String? _hostError;
  bool _testing = false;
  bool _showData = false;

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _saveHost() async {
    try {
      await ref.read(ollamaHostProvider.notifier).set(_hostController.text);
      _hostController.text = ref.read(ollamaHostProvider);
      setState(() => _hostError = null);
    } on FormatException catch (error) {
      setState(() => _hostError = error.message);
    }
  }

  Future<void> _testConnection() async {
    HapticFeedback.lightImpact();
    setState(() => _testing = true);
    final live = await ref.read(ollamaServiceProvider).ping();
    if (!mounted) {
      return;
    }
    ref.read(appStateProvider.notifier).setOllamaStatus(live);
    setState(() => _testing = false);
  }

  Future<void> _seed() async {
    HapticFeedback.lightImpact();
    await ref.read(appStateProvider.notifier).seedDemoWeek();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo week added before today.')),
      );
    }
  }

  Future<void> _reset() async {
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.of(context);
    final reset = await confirmAndResetAllData(context, ref);
    if (!reset || !mounted) {
      return;
    }
    navigator.pop();
    router?.go('/onboarding');
  }

  String _storedDataJson() {
    final state = ref.read(appStateProvider);
    return const JsonEncoder.withIndent('  ').convert({
      'userName': state.userName,
      'baseline': state.baseline?.toMap(),
      'counters': state.counters,
      'signals': state.signals.map((s) => s.toMap()).toList(),
      'xpEvents': state.xpEvents.map((e) => e.toMap()).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final host = ref.watch(ollamaHostProvider);
    final realScore = state.breakdown.score;
    final shown = state.cogniPulseScore;
    final mood = MochiMoodStateX.fromScore(shown);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.lg),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.textPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Text('Developer tools', style: AppTheme.displaySmall),
                ],
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                'For presenting. Overrides are labelled in the app and never saved.',
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.lg),

              // ── Score override ────────────────────────────────────
              _Section(
                title: 'Score override',
                children: [
                  Text(
                    state.scoreOverride == null
                        ? 'Showing the real score: $realScore (${mood.label})'
                        : 'Showing $shown (${mood.label}) · real score $realScore',
                    style: AppTheme.bodyMedium,
                  ),
                  Slider(
                    value: shown.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$shown',
                    activeColor: mood.bodyColor,
                    onChanged: (value) => ref
                        .read(appStateProvider.notifier)
                        .setScoreOverride(value.round()),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: state.scoreOverride == null
                          ? null
                          : () => ref
                              .read(appStateProvider.notifier)
                              .setScoreOverride(null),
                      child: const Text('Use real score'),
                    ),
                  ),
                ],
              ),

              // ── Demo data ────────────────────────────────────────
              _Section(
                title: 'Demo data',
                children: [
                  Text(
                    'Adds six believable days of check-ins before today. '
                    'Seeding again replaces the earlier demo rows.',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Wrap(
                    spacing: AppTheme.sm,
                    runSpacing: AppTheme.sm,
                    children: [
                      FilledButton(
                        onPressed: _seed,
                        child: const Text('Seed demo week'),
                      ),
                      OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                        ),
                        child: const Text('Reset all data'),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Ollama ───────────────────────────────────────────
              _Section(
                title: 'Mochi chat (Ollama)',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Current host: $host', style: AppTheme.bodySmall),
                      ),
                      _StatusChip(live: state.isOllamaLive),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sm),
                  TextField(
                    key: const ValueKey('ollama-host'),
                    controller: _hostController,
                    keyboardType: TextInputType.url,
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '192.168.1.5:11434',
                      errorText: _hostError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
                      ),
                    ),
                    onSubmitted: (_) => _saveHost(),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Wrap(
                    spacing: AppTheme.sm,
                    runSpacing: AppTheme.sm,
                    children: [
                      FilledButton(onPressed: _saveHost, child: const Text('Save')),
                      OutlinedButton(
                        onPressed: _testing ? null : _testConnection,
                        child: Text(_testing ? 'Testing…' : 'Test connection'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(ollamaHostProvider.notifier).reset();
                          _hostController.text = ref.read(ollamaHostProvider);
                        },
                        child: const Text('Default'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    'Emulator: 10.0.2.2:11434. Real phone: your computer\'s Wi-Fi '
                    'address, with Ollama started as OLLAMA_HOST=0.0.0.0.',
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),

              // ── Stored data ──────────────────────────────────────
              _Section(
                title: 'Stored data',
                children: [
                  Text(
                    '${state.signals.length} check-ins · ${state.xpEvents.length} XP events · '
                    'baseline ${state.baseline == null ? 'not set' : 'set'}',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.sm),
                  OutlinedButton(
                    onPressed: () => setState(() => _showData = !_showData),
                    child: Text(_showData ? 'Hide stored data' : 'Show stored data'),
                  ),
                  if (_showData) ...[
                    const SizedBox(height: AppTheme.sm),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.sm),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGlassDim,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
                      ),
                      child: SelectionArea(
                        child: Text(_storedDataJson(), style: AppTheme.caption),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.headlineMed),
            const SizedBox(height: AppTheme.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool live;

  const _StatusChip({required this.live});

  @override
  Widget build(BuildContext context) {
    final color = live ? AppTheme.primaryLight : AppTheme.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        live ? 'LIVE' : 'MOCK',
        style: AppTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
