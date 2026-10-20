import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';

/// Starts a new day in app state when the calendar date changes while the
/// app stays open, so quests and today's score reset at midnight.
/// (Resuming from the background is handled by the app state provider.)
class DayRolloverWatcher extends ConsumerStatefulWidget {
  final Widget child;
  final Duration checkEvery;

  const DayRolloverWatcher({
    required this.child,
    this.checkEvery = const Duration(minutes: 1),
    super.key,
  });

  @override
  ConsumerState<DayRolloverWatcher> createState() => _DayRolloverWatcherState();
}

class _DayRolloverWatcherState extends ConsumerState<DayRolloverWatcher> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.checkEvery, (_) => _check());
  }

  void _check() {
    final now = ref.read(appClockProvider)();
    final asOf = ref.read(appStateProvider).asOf;
    if (now.year != asOf.year || now.month != asOf.month || now.day != asOf.day) {
      ref.read(appStateProvider.notifier).refreshClock();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
