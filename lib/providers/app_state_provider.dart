import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/models/user_profile.dart';
import 'package:zeno/models/cognipulse_reading.dart';
import 'package:zeno/services/face_scan_repository.dart';

// ── Shared Preferences ──────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

// ── App State ────────────────────────────────────────────────────────
class AppState {
  final String userId;
  final UserProfile user;
  final int cogniPulseScore;
  final List<CogniPulseReading> weekReadings;
  final List<FaceScanEntry> faceScans;
  final List<Quest> quests;
  final bool onboardingComplete;
  final bool isOllamaLive;
  final int totalXpToday;
  final int dialogueCycleCount;

  const AppState({
    required this.userId,
    required this.user,
    required this.cogniPulseScore,
    required this.weekReadings,
    required this.faceScans,
    required this.quests,
    required this.onboardingComplete,
    required this.isOllamaLive,
    required this.totalXpToday,
    this.dialogueCycleCount = 0,
  });

  AppState copyWith({
    String? userId,
    UserProfile? user,
    int? cogniPulseScore,
    List<CogniPulseReading>? weekReadings,
    List<FaceScanEntry>? faceScans,
    List<Quest>? quests,
    bool? onboardingComplete,
    bool? isOllamaLive,
    int? totalXpToday,
    int? dialogueCycleCount,
  }) =>
      AppState(
        userId: userId ?? this.userId,
        user: user ?? this.user,
        cogniPulseScore: cogniPulseScore ?? this.cogniPulseScore,
        weekReadings: weekReadings ?? this.weekReadings,
        faceScans: faceScans ?? this.faceScans,
        quests: quests ?? this.quests,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        isOllamaLive: isOllamaLive ?? this.isOllamaLive,
        totalXpToday: totalXpToday ?? this.totalXpToday,
        dialogueCycleCount: dialogueCycleCount ?? this.dialogueCycleCount,
      );

  int get scoreDelta {
    if (weekReadings.length < 2) {
      return 0;
    }
    return weekReadings.last.score - weekReadings[weekReadings.length - 2].score;
  }

  FaceScanEntry? get latestFaceScan => faceScans.isEmpty ? null : faceScans.first;
}

class AppStateNotifier extends StateNotifier<AppState> {
  static const _weekReadingsKey = 'zeno.week_readings';

  final SharedPreferences _prefs;
  final FaceScanRepository _faceScanRepository;

  AppStateNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        _faceScanRepository = FaceScanRepository(prefs),
        super(_buildInitialState(prefs)) {
    state = state.copyWith(
      user: _copyUser(avgCogniPulse: _averageScore(state.weekReadings)),
    );
  }

  static AppState _buildInitialState(SharedPreferences prefs) {
    final readings = _loadWeekReadings(prefs);
    return AppState(
      userId: 'alex',
      user: MockData.user,
      cogniPulseScore: readings.last.score,
      weekReadings: readings,
      faceScans: FaceScanRepository(prefs).loadHistory(),
      quests: MockData.quests,
      onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
      isOllamaLive: false,
      totalXpToday: 120,
    );
  }

  static List<CogniPulseReading> _loadWeekReadings(SharedPreferences prefs) {
    final raw = prefs.getString(_weekReadingsKey);
    if (raw == null || raw.isEmpty) {
      return MockData.weekReadings;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return MockData.weekReadings;
    }
    final readings = decoded
        .whereType<Map>()
        .map((entry) => CogniPulseReading.fromMap(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
    if (readings.isEmpty) {
      return MockData.weekReadings;
    }
    readings.sort((left, right) => left.date.compareTo(right.date));
    return readings;
  }

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
    final reading = CogniPulseReading(
      date: DateTime.now(),
      score: score.clamp(0, 100),
      stressIndex: state.weekReadings.last.stressIndex,
      focusLevel: state.weekReadings.last.focusLevel,
      moodScore: state.weekReadings.last.moodScore,
      source: 'manual',
    );
    _applyReading(reading);
  }

  void applyGameContribution(int adjustment) {
    state = state.copyWith(
      cogniPulseScore: (state.cogniPulseScore + adjustment).clamp(0, 100),
    );
  }

  void setOllamaStatus(bool live) {
    state = state.copyWith(isOllamaLive: live);
  }

  void updateUserName(String name) {
    final updated = _copyUser(name: name);
    state = state.copyWith(user: updated);
  }

  void cycleDialogue() {
    state = state.copyWith(dialogueCycleCount: state.dialogueCycleCount + 1);
  }

  Future<void> recordFaceScan(FaceScanEntry scan) async {
    final readings = _mergeReading(scan.toReading());
    final scans = [scan, ...state.faceScans]..sort(
        (left, right) => right.scannedAt.compareTo(left.scannedAt),
      );
    final trimmedScans = scans.take(20).toList(growable: false);
    state = state.copyWith(
      cogniPulseScore: scan.score,
      weekReadings: readings,
      faceScans: trimmedScans,
      user: _copyUser(avgCogniPulse: _averageScore(readings)),
    );
    await _persistWeekReadings(readings);
    await _faceScanRepository.saveHistory(trimmedScans);
  }

  void _applyReading(CogniPulseReading reading) {
    final readings = _mergeReading(reading);
    state = state.copyWith(
      cogniPulseScore: reading.score,
      weekReadings: readings,
      user: _copyUser(avgCogniPulse: _averageScore(readings)),
    );
    _persistWeekReadings(readings);
  }

  List<CogniPulseReading> _mergeReading(CogniPulseReading reading) {
    final readings = [...state.weekReadings];
    if (readings.isNotEmpty && _isSameDay(readings.last.date, reading.date)) {
      readings[readings.length - 1] = reading;
    } else {
      readings.add(reading);
    }
    readings.sort((left, right) => left.date.compareTo(right.date));
    if (readings.length > 7) {
      return readings.sublist(readings.length - 7);
    }
    return readings;
  }

  Future<void> _persistWeekReadings(List<CogniPulseReading> readings) {
    final payload = readings.map((reading) => reading.toMap()).toList(growable: false);
    return _prefs.setString(_weekReadingsKey, jsonEncode(payload));
  }

  double _averageScore(List<CogniPulseReading> readings) {
    if (readings.isEmpty) {
      return 0;
    }
    return readings.map((reading) => reading.score).reduce((a, b) => a + b) /
        readings.length;
  }

  bool _isSameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  UserProfile _copyUser({
    String? name,
    double? avgCogniPulse,
  }) {
    return UserProfile(
      name: name ?? state.user.name,
      level: state.user.level,
      xp: state.user.xp,
      xpToNextLevel: state.user.xpToNextLevel,
      currentStreak: state.user.currentStreak,
      totalQuestsCompleted: state.user.totalQuestsCompleted,
      avgCogniPulse: avgCogniPulse ?? state.user.avgCogniPulse,
      avatarId: state.user.avatarId,
      badges: state.user.badges,
    );
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
