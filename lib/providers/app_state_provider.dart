import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/models/user_profile.dart';
import 'package:zeno/models/cognipulse_reading.dart';

// ── Shared Preferences ──────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

// ── App State ────────────────────────────────────────────────────────
class AppState {
  final UserProfile user;
  final int cogniPulseScore;
  final List<CogniPulseReading> weekReadings;
  final List<Quest> quests;
  final bool onboardingComplete;
  final bool isOllamaLive;
  final int totalXpToday;

  const AppState({
    required this.user,
    required this.cogniPulseScore,
    required this.weekReadings,
    required this.quests,
    required this.onboardingComplete,
    required this.isOllamaLive,
    required this.totalXpToday,
  });

  AppState copyWith({
    UserProfile? user,
    int? cogniPulseScore,
    List<CogniPulseReading>? weekReadings,
    List<Quest>? quests,
    bool? onboardingComplete,
    bool? isOllamaLive,
    int? totalXpToday,
  }) =>
      AppState(
        user: user ?? this.user,
        cogniPulseScore: cogniPulseScore ?? this.cogniPulseScore,
        weekReadings: weekReadings ?? this.weekReadings,
        quests: quests ?? this.quests,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        isOllamaLive: isOllamaLive ?? this.isOllamaLive,
        totalXpToday: totalXpToday ?? this.totalXpToday,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(SharedPreferences prefs)
      : super(AppState(
          user: MockData.user,
          cogniPulseScore: MockData.currentScore,
          weekReadings: MockData.weekReadings,
          quests: MockData.quests,
          onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
          isOllamaLive: false,
          totalXpToday: 120,
        ));

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
  }

  void completeQuest(String questId) {
    final updated = state.quests.map((q) {
      if (q.id == questId && q.status == QuestStatus.available) {
        return q.copyWith(status: QuestStatus.completed);
      }
      return q;
    }).toList();
    final xpGained = state.quests.firstWhere((q) => q.id == questId).xpReward;
    final newScore = (state.cogniPulseScore + 2).clamp(0, 100);
    state = state.copyWith(
      quests: updated,
      totalXpToday: state.totalXpToday + xpGained,
      cogniPulseScore: newScore,
    );
  }

  void updateCogniPulse(int score) {
    state = state.copyWith(cogniPulseScore: score.clamp(0, 100));
  }

  void setOllamaStatus(bool live) {
    state = state.copyWith(isOllamaLive: live);
  }

  void updateUserName(String name) {
    final updated = UserProfile(
      name: name,
      level: state.user.level,
      xp: state.user.xp,
      xpToNextLevel: state.user.xpToNextLevel,
      currentStreak: state.user.currentStreak,
      totalQuestsCompleted: state.user.totalQuestsCompleted,
      avgCogniPulse: state.user.avgCogniPulse,
      avatarId: state.user.avatarId,
      badges: state.user.badges,
    );
    state = state.copyWith(user: updated);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppStateNotifier(prefs);
});

// ── Derived Providers ─────────────────────────────────────────────────
final cogniPulseProvider = Provider<int>(
  (ref) => ref.watch(appStateProvider).cogniPulseScore,
);

final mochiMoodProvider = Provider<MochiMoodState>(
  (ref) => MochiMoodStateX.fromScore(ref.watch(cogniPulseProvider)),
);

final isOllamaLiveProvider = Provider<bool>(
  (ref) => ref.watch(appStateProvider).isOllamaLive,
);

final questsProvider = Provider<List<Quest>>(
  (ref) => ref.watch(appStateProvider).quests,
);

final userProvider = Provider<UserProfile>(
  (ref) => ref.watch(appStateProvider).user,
);

// ── Dialogue State ────────────────────────────────────────────────────
final dialogueIndexProvider = StateProvider.family<int, String>(
  (ref, mood) => 0,
);
