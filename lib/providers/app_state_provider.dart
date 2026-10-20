import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/user_profile.dart';
import 'package:zeno/models/xp_event.dart';
import 'package:zeno/services/cognipulse_engine.dart';
import 'package:zeno/services/demo_seeder.dart';
import 'package:zeno/services/face_scan_repository.dart';
import 'package:zeno/services/game_repository.dart';
import 'package:zeno/services/game_recommender.dart';
import 'package:zeno/services/progress_engine.dart';
import 'package:zeno/services/wellness_repository.dart';

// ── Shared Preferences ──────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main.dart'),
);

// ── App State ────────────────────────────────────────────────────────
/// Raw facts the user created, plus everything derived from them.
///
/// Only the constructor fields are stored. Score, XP, level, streak, quests
/// and badges are recomputed from them, so they can never disagree.
class AppState {
  static const defaultName = 'Friend';

  /// XP for the first check-in of each kind per day.
  static const checkInXp = {
    SignalType.selfReport: 5,
    SignalType.typing: 15,
    SignalType.faceScan: 15,
  };

  final DateTime asOf;
  final String userName;
  final List<SignalReading> signals;
  final List<XpEvent> xpEvents;
  final BaselineResult? baseline;
  final Map<String, int> counters;
  final List<FaceScanEntry> faceScans;
  final bool onboardingComplete;
  final bool isOllamaLive;
  final int dialogueCycleCount;

  /// Demo-only score set from the developer panel. Kept in memory, never
  /// saved, and labelled wherever the score is shown.
  final int? scoreOverride;

  AppState({
    required this.asOf,
    required this.userName,
    required this.signals,
    required this.xpEvents,
    required this.baseline,
    required this.counters,
    required this.faceScans,
    required this.onboardingComplete,
    required this.isOllamaLive,
    this.dialogueCycleCount = 0,
    this.scoreOverride,
  });

  AppState copyWith({
    DateTime? asOf,
    String? userName,
    List<SignalReading>? signals,
    List<XpEvent>? xpEvents,
    BaselineResult? baseline,
    Map<String, int>? counters,
    List<FaceScanEntry>? faceScans,
    bool? onboardingComplete,
    bool? isOllamaLive,
    int? dialogueCycleCount,
    int? scoreOverride,
    bool clearScoreOverride = false,
  }) =>
      AppState(
        asOf: asOf ?? this.asOf,
        userName: userName ?? this.userName,
        signals: signals ?? this.signals,
        xpEvents: xpEvents ?? this.xpEvents,
        baseline: baseline ?? this.baseline,
        counters: counters ?? this.counters,
        faceScans: faceScans ?? this.faceScans,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        isOllamaLive: isOllamaLive ?? this.isOllamaLive,
        dialogueCycleCount: dialogueCycleCount ?? this.dialogueCycleCount,
        scoreOverride:
            clearScoreOverride ? null : scoreOverride ?? this.scoreOverride,
      );

  // ── CogniPulse ──────────────────────────────────────────────────
  late final CogniPulseBreakdown breakdown =
      CogniPulseEngine.today(signals, baseline, asOf);

  int get cogniPulseScore => scoreOverride ?? breakdown.score;

  late final List<DaySummary> weekDays =
      CogniPulseEngine.lastDays(signals, baseline, asOf);

  /// Today's score minus the most recent earlier day with check-ins.
  int get scoreDelta {
    if (!breakdown.hasCheckInToday) {
      return 0;
    }
    final earlier = weekDays.take(weekDays.length - 1).where((d) => d.hasData);
    return earlier.isEmpty ? 0 : cogniPulseScore - earlier.last.score!;
  }

  List<SignalReading> get signalsToday =>
      signals.where((s) => _isToday(s.at)).toList(growable: false);

  bool hasCheckedInToday(SignalType type) =>
      signalsToday.any((s) => s.type == type);

  /// The value of today's latest mood check-in, if any.
  int? get todaysMood {
    final moods = signalsToday.where((s) => s.type == SignalType.selfReport);
    return moods.isEmpty ? null : moods.last.score;
  }

  FaceScanEntry? get latestFaceScan => faceScans.isEmpty ? null : faceScans.first;

  /// The game Mochi suggests, from today's stress, mood and face-scan focus.
  String get recommendedGameId {
    final todaySummary = weekDays.last;
    final scan = latestFaceScan;
    return GameRecommender.recommend(
      score: cogniPulseScore,
      stress: todaySummary.stress,
      mood: todaySummary.mood,
      focus: scan != null && _isToday(scan.scannedAt) ? scan.focusLevel : null,
    );
  }

  // ── XP, quests, streak ──────────────────────────────────────────
  int get totalXp => xpEvents.fold(0, (sum, e) => sum + e.amount);

  int get totalXpToday =>
      xpEvents.where((e) => _isToday(e.at)).fold(0, (sum, e) => sum + e.amount);

  Set<String> get questsDoneToday => xpEvents
      .where((e) => e.source == 'quest' && _isToday(e.at))
      .map((e) => e.sourceId)
      .whereType<String>()
      .toSet();

  List<Quest> get quests {
    final done = questsDoneToday;
    return MockData.quests
        .map((q) => done.contains(q.id) ? q.copyWith(status: QuestStatus.completed) : q)
        .toList(growable: false);
  }

  Set<DateTime> get activeDays => {
        for (final s in signals) _dateOnly(s.at),
        for (final e in xpEvents) _dateOnly(e.at),
      };

  late final UserProfile user = _buildUser();

  UserProfile _buildUser() {
    final days = activeDays;
    final longest = ProgressEngine.longestStreak(days);
    final checkIns = signals.where((s) => s.type != SignalType.game).toList();
    final weekWithData = weekDays.where((d) => d.hasData).toList();
    final allDays = CogniPulseEngine.lastDays(
      signals,
      baseline,
      asOf,
      days: WellnessRepository.retention.inDays,
    );

    return UserProfile(
      name: userName,
      level: ProgressEngine.level(totalXp),
      xp: ProgressEngine.xpIntoLevel(totalXp),
      xpToNextLevel: ProgressEngine.xpPerLevel,
      currentStreak: ProgressEngine.currentStreak(days, asOf),
      longestStreak: longest,
      totalQuestsCompleted: xpEvents.where((e) => e.source == 'quest').length,
      avgCogniPulse: weekWithData.isEmpty
          ? null
          : weekWithData.fold<int>(0, (sum, d) => sum + d.score!) / weekWithData.length,
      badges: ProgressEngine.badges(BadgeStats(
        checkIns: checkIns.length,
        earlyCheckInDays:
            checkIns.where((s) => s.at.hour < 8).map((s) => _dateOnly(s.at)).toSet().length,
        longestStreak: longest,
        mochiTaps: counters['mochi_taps'] ?? 0,
        daysAbove80: allDays.where((d) => (d.score ?? 0) >= 80).length,
        breathingSessions: counters['breathing_sessions'] ?? 0,
        nightCheckIn: checkIns.any((s) => s.at.hour >= 23),
      )),
    );
  }

  bool _isToday(DateTime value) => _dateOnly(value) == _dateOnly(asOf);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class AppStateNotifier extends StateNotifier<AppState> {
  /// Pre-Phase-1 storage of a mostly mocked week; no longer read.
  static const _legacyWeekReadingsKey = 'zeno.week_readings';

  /// Device settings that survive "Reset all data".
  static const preservedOnReset = {'zeno.ollama_host'};

  final SharedPreferences _prefs;
  final WellnessRepository _repo;
  final FaceScanRepository _faceScanRepository;
  final DateTime Function() _clock;
  final Future<void> Function() _clearGameData;

  AppStateNotifier(
    SharedPreferences prefs, {
    DateTime Function()? clock,
    Future<void> Function()? clearGameData,
  })  : _prefs = prefs,
        _repo = WellnessRepository(prefs),
        _faceScanRepository = FaceScanRepository(prefs),
        _clock = clock ?? DateTime.now,
        _clearGameData = clearGameData ?? GameRepository().clearAll,
        super(_load(prefs, clock ?? DateTime.now));

  static AppState _load(SharedPreferences prefs, DateTime Function() clock) {
    final repo = WellnessRepository(prefs);
    final faceScans = FaceScanRepository(prefs).loadHistory();
    var signals = repo.loadSignals();
    // Face scans saved before signals existed still count as check-ins.
    if (!prefs.containsKey(WellnessRepository.signalsKey) && faceScans.isNotEmpty) {
      signals = faceScans.map((scan) => scan.toSignal()).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
    }
    prefs.remove(_legacyWeekReadingsKey);

    return AppState(
      asOf: clock(),
      userName: repo.loadUserName() ?? AppState.defaultName,
      signals: signals,
      xpEvents: repo.loadXpEvents(),
      baseline: repo.loadBaseline(),
      counters: repo.loadCounters(),
      faceScans: faceScans,
      onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
      isOllamaLive: false,
    );
  }

  /// Deletes everything the user has logged (check-ins, XP, baseline, name,
  /// face scans, game history) and returns the app to a fresh install.
  Future<void> resetAllData() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith('zeno.') && !preservedOnReset.contains(key))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    await _prefs.remove('onboarding_complete');
    await _clearGameData();
    state = _load(_prefs, _clock);
  }

  /// Developer panel: pin the displayed score (clamped to 0–100), or pass
  /// null to go back to the real one.
  void setScoreOverride(int? value) {
    state = value == null
        ? state.copyWith(clearScoreOverride: true)
        : state.copyWith(scoreOverride: value.clamp(0, 100));
  }

  /// Developer panel: replace any earlier demo rows with a fresh demo week.
  Future<void> seedDemoWeek() async {
    final now = _clock();
    final demo = DemoSeeder.week(now);
    final signals = [
      ...state.signals.where((s) => !DemoSeeder.isDemoSignal(s)),
      ...demo.signals,
    ]..sort((a, b) => a.at.compareTo(b.at));
    final events = [
      ...state.xpEvents.where((e) => !DemoSeeder.isDemoXp(e)),
      ...demo.xpEvents,
    ]..sort((a, b) => a.at.compareTo(b.at));
    state = state.copyWith(asOf: now, signals: signals, xpEvents: events);
    await _repo.saveSignals(signals);
    await _repo.saveXpEvents(events);
  }

  /// Re-derives everything for the current time, e.g. after midnight.
  void refreshClock() {
    state = state.copyWith(asOf: _clock());
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
  }

  Future<void> saveBaseline(BaselineResult baseline) async {
    state = state.copyWith(baseline: baseline, asOf: _clock());
    await _repo.saveBaseline(baseline);
  }

  Future<void> updateUserName(String name) async {
    state = state.copyWith(userName: name);
    await _repo.saveUserName(name);
  }

  /// Self-reported mood from the Home check-in, 0–100.
  Future<void> logMood(int value) {
    final mood = value.clamp(0, 100);
    return _addSignal(SignalReading(
      type: SignalType.selfReport,
      score: mood,
      at: _clock(),
      mood: mood.toDouble(),
    ));
  }

  Future<void> recordTypingCheckIn({
    required int score,
    required double stress,
    required String note,
  }) {
    return _addSignal(SignalReading(
      type: SignalType.typing,
      score: score,
      at: _clock(),
      stress: stress,
      note: note,
    ));
  }

  Future<void> recordFaceScan(FaceScanEntry scan) async {
    final scans = [scan, ...state.faceScans]
      ..sort((left, right) => right.scannedAt.compareTo(left.scannedAt));
    final trimmedScans = scans.take(20).toList(growable: false);
    state = state.copyWith(faceScans: trimmedScans);
    await _faceScanRepository.saveHistory(trimmedScans);
    await _addSignal(scan.toSignal());
  }

  /// A finished game earns its XP; its play signal feeds CogniPulse.
  /// Games quit early earn and change nothing.
  Future<void> recordGameResult({
    required String gameId,
    required int xpReward,
    required bool completed,
    int? signalScore,
  }) async {
    if (!completed) {
      return;
    }
    final now = _clock();
    final events = [
      ...state.xpEvents,
      XpEvent(source: 'game', sourceId: gameId, amount: xpReward, at: now),
    ];
    var signals = state.signals;
    if (signalScore != null) {
      final score = signalScore.clamp(0, 100);
      signals = [
        ...signals,
        SignalReading(
          type: SignalType.game,
          score: score,
          at: now,
          stress: (100 - score).toDouble(),
          note: gameId,
        ),
      ];
    }
    state = state.copyWith(asOf: now, xpEvents: events, signals: signals);
    await _repo.saveXpEvents(events);
    await _repo.saveSignals(signals);
  }

  /// Returns false when the quest was already completed today.
  Future<bool> completeQuest(String questId) async {
    final now = _clock();
    state = state.copyWith(asOf: now);
    if (state.questsDoneToday.contains(questId)) {
      return false;
    }
    final quest = MockData.quests.firstWhere((q) => q.id == questId);
    final events = [
      ...state.xpEvents,
      XpEvent(source: 'quest', sourceId: questId, amount: quest.xpReward, at: now),
    ];
    state = state.copyWith(xpEvents: events);
    await _repo.saveXpEvents(events);
    return true;
  }

  Future<void> recordBreathingSession() => _increment('breathing_sessions');

  void setOllamaStatus(bool live) {
    state = state.copyWith(isOllamaLive: live);
  }

  /// Called on every Mochi tap: shows a new line and counts the tap.
  void cycleDialogue() {
    state = state.copyWith(dialogueCycleCount: state.dialogueCycleCount + 1);
    _increment('mochi_taps');
  }

  Future<void> _increment(String counter) async {
    final counters = {...state.counters};
    counters[counter] = (counters[counter] ?? 0) + 1;
    state = state.copyWith(counters: counters);
    await _repo.saveCounters(counters);
  }

  Future<void> _addSignal(SignalReading reading) async {
    final firstToday = !state.copyWith(asOf: reading.at).hasCheckedInToday(reading.type);
    final signals = [...state.signals, reading];
    final xp = AppState.checkInXp[reading.type];
    final awardsXp = firstToday && xp != null;
    final events = awardsXp
        ? [
            ...state.xpEvents,
            XpEvent(source: reading.type.name, amount: xp, at: reading.at),
          ]
        : state.xpEvents;
    state = state.copyWith(asOf: reading.at, signals: signals, xpEvents: events);
    await _repo.saveSignals(signals);
    if (awardsXp) {
      await _repo.saveXpEvents(events);
    }
  }
}

/// The time source for app state; tests override it.
final appClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = AppStateNotifier(prefs, clock: ref.watch(appClockProvider));
  // Coming back to the app after midnight starts a new day: quests, today's
  // XP and today's score are re-derived for the current date.
  final lifecycle = AppLifecycleListener(onResume: notifier.refreshClock);
  ref.onDispose(lifecycle.dispose);
  return notifier;
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
