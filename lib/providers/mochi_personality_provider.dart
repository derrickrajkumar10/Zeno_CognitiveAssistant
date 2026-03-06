import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/mock_data.dart';

/// Mochi's personality engine -- drives dialogue, reactions, and awareness.
///
/// This provider layer makes Mochi feel alive by considering:
/// - Current mood (from CogniPulse score)
/// - Time of day (morning/afternoon/evening/night)
/// - User's streak status
/// - User's name for personalization

enum MochiTimeOfDay { morning, afternoon, evening, night }

enum MochiReactionType {
  happySquish,
  excitedBounce,
  sleepyYawn,
  thinkingPose,
  celebration,
  gentleNod,
}

class MochiPersonality {
  final MochiMoodState mood;
  final MochiTimeOfDay timeOfDay;
  final String userName;
  final int streak;
  final int cogniPulseScore;
  final int scoreDelta;

  const MochiPersonality({
    required this.mood,
    required this.timeOfDay,
    required this.userName,
    required this.streak,
    required this.cogniPulseScore,
    required this.scoreDelta,
  });

  /// Get a contextual greeting based on time of day
  String get greeting {
    switch (timeOfDay) {
      case MochiTimeOfDay.morning:
        return _pick([
          'Good morning, $userName',
          'Rise and shine, $userName',
          'Morning! Mochi has been waiting',
          'Early bird, $userName. Mochi approves.',
        ]);
      case MochiTimeOfDay.afternoon:
        return _pick([
          'Hey $userName',
          'Afternoon check-in, $userName',
          '$userName! Perfect timing.',
          'Mochi was just thinking about you.',
        ]);
      case MochiTimeOfDay.evening:
        return _pick([
          'Evening, $userName',
          'Winding down, $userName?',
          'Hey. How was your day, $userName?',
          'Mochi is here for the evening shift.',
        ]);
      case MochiTimeOfDay.night:
        return _pick([
          'Still up, $userName?',
          'Late night, huh? Mochi is here.',
          'Night owl mode, $userName.',
          'Mochi is yawning but still here for you.',
        ]);
    }
  }

  /// Get a streak-aware nudge
  String? get streakMessage {
    if (streak == 0) return null;
    if (streak == 1) return 'Day 1. Every streak starts here.';
    if (streak == 3) return 'Day 3! You are building something real.';
    if (streak == 5) return 'Day 5. Mochi is genuinely impressed.';
    if (streak == 7) return '7 days straight. You are unstoppable, $userName.';
    if (streak > 7) return '$streak-day streak. Mochi has never been prouder.';
    return 'Day $streak. Keep it going.';
  }

  /// Get contextual dialogue based on mood
  String get moodDialogue {
    final dialogues = _dialogueForMood;
    return dialogues[Random().nextInt(dialogues.length)];
  }

  List<String> get _dialogueForMood {
    switch (mood) {
      case MochiMoodState.thriving:
        return MockData.thrivingDialogue;
      case MochiMoodState.balanced:
        return MockData.balancedDialogue;
      case MochiMoodState.drifting:
        return MockData.driftingDialogue;
      case MochiMoodState.struggling:
        return MockData.strugglingDialogue;
    }
  }

  /// What kind of tap reaction Mochi should show right now
  MochiReactionType get defaultReaction {
    if (timeOfDay == MochiTimeOfDay.night) return MochiReactionType.sleepyYawn;
    switch (mood) {
      case MochiMoodState.thriving:
        return MochiReactionType.excitedBounce;
      case MochiMoodState.balanced:
        return MochiReactionType.happySquish;
      case MochiMoodState.drifting:
        return MochiReactionType.gentleNod;
      case MochiMoodState.struggling:
        return MochiReactionType.gentleNod;
    }
  }

  /// Score change commentary
  String? get deltaCommentary {
    if (scoreDelta > 5) return 'Your pulse is climbing. Mochi sees it.';
    if (scoreDelta < -5) return 'Dipped a bit from yesterday. That is okay.';
    return null;
  }

  String _pick(List<String> options) {
    return options[Random().nextInt(options.length)];
  }
}

/// Provider that builds MochiPersonality from current app state
final mochiPersonalityProvider = Provider<MochiPersonality>((ref) {
  final state = ref.watch(appStateProvider);
  final mood = MochiMoodStateX.fromScore(state.cogniPulseScore);
  final hour = DateTime.now().hour;

  MochiTimeOfDay timeOfDay;
  if (hour >= 5 && hour < 12) {
    timeOfDay = MochiTimeOfDay.morning;
  } else if (hour >= 12 && hour < 17) {
    timeOfDay = MochiTimeOfDay.afternoon;
  } else if (hour >= 17 && hour < 21) {
    timeOfDay = MochiTimeOfDay.evening;
  } else {
    timeOfDay = MochiTimeOfDay.night;
  }

  return MochiPersonality(
    mood: mood,
    timeOfDay: timeOfDay,
    userName: state.user.name,
    streak: state.user.currentStreak,
    cogniPulseScore: state.cogniPulseScore,
    scoreDelta: state.scoreDelta,
  );
});

/// The current dialogue to display -- picks from greeting, streak, mood, or delta.
/// Watches dialogueCycleCount so tapping Mochi triggers a new pick.
final mochiCurrentDialogueProvider = Provider<String>((ref) {
  final personality = ref.watch(mochiPersonalityProvider);
  // Watch the cycle count so each tap triggers a rebuild
  ref.watch(appStateProvider.select((s) => s.dialogueCycleCount));

  // Weighted random pick: greeting 30%, streak 20%, mood 40%, delta 10%
  final roll = Random().nextDouble();
  if (roll < 0.3) return personality.greeting;
  if (roll < 0.5 && personality.streakMessage != null) {
    return personality.streakMessage!;
  }
  if (roll < 0.9) return personality.moodDialogue;
  if (personality.deltaCommentary != null) return personality.deltaCommentary!;
  return personality.moodDialogue;
});
