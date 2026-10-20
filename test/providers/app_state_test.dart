import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/face_scan_repository.dart';

void main() {
  late SharedPreferences prefs;
  var now = DateTime(2026, 10, 16, 10);

  AppStateNotifier notifier() => AppStateNotifier(prefs, clock: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 16, 10);
  });

  test('a fresh install has no fake progress', () {
    final state = notifier().state;
    expect(state.user.level, 1);
    expect(state.totalXp, 0);
    expect(state.totalXpToday, 0);
    expect(state.user.currentStreak, 0);
    expect(state.user.totalQuestsCompleted, 0);
    expect(state.user.avgCogniPulse, isNull);
    expect(state.user.badges.where((b) => b.unlocked), isEmpty);
    expect(state.cogniPulseScore, 60);
    expect(state.weekDays.where((d) => d.hasData), isEmpty);
  });

  test('completing a quest awards its XP once and survives a restart', () async {
    final first = notifier();
    expect(await first.completeQuest('walk'), isTrue);
    expect(await first.completeQuest('walk'), isFalse);
    expect(first.state.totalXpToday, 50);

    final restarted = notifier().state;
    expect(restarted.totalXp, 50);
    expect(restarted.user.totalQuestsCompleted, 1);
    expect(
      restarted.quests.firstWhere((q) => q.id == 'walk').status,
      QuestStatus.completed,
    );
    expect(restarted.user.currentStreak, 1);
  });

  test('quests and today\'s XP reset the next day but total XP stays', () async {
    await notifier().completeQuest('walk');
    now = DateTime(2026, 10, 17, 9);
    final nextDay = notifier().state;
    expect(nextDay.totalXpToday, 0);
    expect(nextDay.totalXp, 50);
    expect(nextDay.quests.every((q) => q.status == QuestStatus.available), isTrue);
    expect(nextDay.user.currentStreak, 1);
  });

  test('a mood check-in moves the score and gives XP only once a day', () async {
    final app = notifier();
    await app.logMood(90);
    expect(app.state.cogniPulseScore, 78);
    expect(app.state.todaysMood, 90);
    await app.logMood(10);
    expect(app.state.cogniPulseScore, 30);
    expect(app.state.totalXpToday, 5);
    expect(notifier().state.cogniPulseScore, 30);
  });

  test('the baseline questionnaire becomes the starting score', () async {
    final app = notifier();
    await app.saveBaseline(BaselineResult(answers: const [1, 1, 1, 1, 1], at: now));
    expect(app.state.cogniPulseScore, 0);
    expect(notifier().state.baseline, isNotNull);
  });

  test('a finished game gives XP and a game signal', () async {
    final app = notifier();
    await app.recordGameResult(gameId: 'wave_sync', xpReward: 30, completed: true, signalScore: 80);
    expect(app.state.totalXpToday, 30);
    expect(app.state.signals.single.type, SignalType.game);
  });

  test('a game quit early gives no XP and no signal', () async {
    final app = notifier();
    await app.recordGameResult(gameId: 'wave_sync', xpReward: 30, completed: false, signalScore: 80);
    expect(app.state.totalXpToday, 0);
    expect(app.state.signals, isEmpty);
  });

  test('Mochi taps and breathing sessions are counted and persisted', () async {
    final app = notifier();
    app.cycleDialogue();
    app.cycleDialogue();
    await app.recordBreathingSession();
    final restarted = notifier().state;
    expect(restarted.counters['mochi_taps'], 2);
    expect(restarted.counters['breathing_sessions'], 1);
  });

  test('the user name persists', () async {
    await notifier().updateUserName('Sam');
    expect(notifier().state.user.name, 'Sam');
  });

  test('corrupt face scan history starts the app with no scans', () async {
    await prefs.setString(FaceScanRepository.storageKey, '{not json');
    expect(notifier().state.faceScans, isEmpty);

    await prefs.setString(FaceScanRepository.storageKey, '[{"id": 7}]');
    expect(notifier().state.faceScans, isEmpty);
  });

  testWidgets('coming back to the app on a new day resets today',
      (tester) async {
    var clockNow = DateTime(2026, 10, 16, 23, 50);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appClockProvider.overrideWithValue(() => clockNow),
    ]);
    addTearDown(container.dispose);

    await container.read(appStateProvider.notifier).completeQuest('walk');
    expect(container.read(appStateProvider).questsDoneToday, contains('walk'));

    clockNow = DateTime(2026, 10, 17, 8);
    for (final lifecycle in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
    }

    expect(container.read(appStateProvider).questsDoneToday, isEmpty);
    expect(container.read(appStateProvider).totalXpToday, 0);
  });

  test('reset clears every piece of user data but keeps device settings',
      () async {
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('zeno.ollama_host', 'http://192.168.1.5:11434');
    final app = notifier();
    app.completeOnboarding();
    await app.updateUserName('Sam');
    await app.logMood(90);
    await app.completeQuest('walk');
    await app.recordBreathingSession();
    await app.saveBaseline(BaselineResult(answers: const [5, 5, 5, 5, 5], at: now));

    await app.resetAllData();

    for (final state in [app.state, notifier().state]) {
      expect(state.totalXp, 0);
      expect(state.signals, isEmpty);
      expect(state.baseline, isNull);
      expect(state.counters, isEmpty);
      expect(state.user.name, AppState.defaultName);
      expect(state.onboardingComplete, isFalse);
    }
    expect(prefs.getBool('onboarding_complete'), isNull);
    expect(prefs.getString('zeno.ollama_host'), 'http://192.168.1.5:11434');
  });
}

