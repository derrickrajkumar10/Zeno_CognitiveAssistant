# ZENO Flutter Demo — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete, polished Flutter frontend demo for ZENO — gamified AI cognitive wellness app — with no backend, all data mocked, Ollama integration with silent fallback.

**Architecture:** Pure Flutter frontend. Riverpod for state. go_router with StatefulShellRoute for 5-tab bottom nav. Mochi drawn with CustomPainter + flutter_animate. All data from mock_data.dart. Ollama at localhost:11434 with 3s timeout and silent fallback.

**Tech Stack:** Flutter (Dart), flutter_riverpod ^2.5.1, go_router ^14.2.7, fl_chart ^0.68.0, flutter_animate ^4.5.0, google_fonts ^6.2.1, http ^1.2.1, shared_preferences ^2.3.2

---

## PRE-FLIGHT CHECKLIST (do before any task)

- [ ] Verify Flutter is installed: `flutter --version`
- [ ] Verify flutter doctor passes: `flutter doctor`
- [ ] Confirm working directory is `d:/Projects/Zeno_WellnessCompanion`
- [ ] Note: docx files and CLAUDE.md already exist in root — `flutter create .` will not overwrite them

---

## DEPENDENCY MAP (read before starting)

```
Task 1  (scaffold)
  └── Task 2  (theme)
  └── Task 3  (models)         ← no dependencies
        └── Task 4  (mock_data)    ← needs models
              └── Task 5  (providers)  ← needs models + mock_data
                    └── Task 6  (ollama service)    ← needs models + providers
                    └── Task 7  (router + shell)    ← needs providers
                          └── Task 8  (ambient bg)      ← needs providers
                          └── Task 9  (mochi widget)    ← needs models + providers
                                └── Task 10 (particle overlay)  ← needs mochi
                                └── Task 11 (dialogue bubble)  ← needs providers + ollama
                                └── Task 12 (cogni ring)       ← needs providers
                                └── Task 13 (quest card + banner) ← needs models
                                      └── Task 14 (onboarding)     ← needs all widgets
                                      └── Task 15 (home screen)    ← needs all widgets
                                      └── Task 16 (quests screen)  ← needs quest_card
                                      └── Task 17 (insights screen) ← needs fl_chart
                                      └── Task 18 (scan screen)    ← needs providers
                                      └── Task 19 (profile screen) ← needs mock_data
                                            └── Task 20 (celebration modal + polish) ← final
```

---

## Task 1: Flutter Project Scaffold

**Files:**
- Create: `pubspec.yaml` (replace generated)
- Create: `lib/main.dart` (replace generated)
- Delete: `test/widget_test.dart` (replace with clean test)
- Create: `analysis_options.yaml` (update)

**Step 1: Create Flutter project in existing directory**
```bash
cd "d:/Projects/Zeno_WellnessCompanion"
flutter create --org com.zeno --project-name zeno --no-pub .
```
Expected: Flutter project scaffolded. Existing files (docx, CLAUDE.md) untouched.

**Step 2: Replace pubspec.yaml with exact content:**
```yaml
name: zeno
description: ZENO — AI Cognitive Wellness Companion
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7
  fl_chart: ^0.68.0
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  http: ^1.2.1
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

**Step 3: Get packages**
```bash
flutter pub get
```
Expected: All packages resolved with no version conflicts.

**Step 4: Write lib/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/router/app_router.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ZenoApp(),
    ),
  );
}

class ZenoApp extends ConsumerWidget {
  const ZenoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ZENO',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Step 5: Verify compiles**
```bash
flutter analyze
```
Expected: Errors for missing imports (router, theme, providers) — that's OK at this stage, we're building foundations next. The scaffold itself should be clean.

---

## Task 2: App Theme

**Files:**
- Create: `lib/theme/app_theme.dart`

**Step 1: Write lib/theme/app_theme.dart**
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core colors
  static const Color backgroundDeep  = Color(0xFF0D1B2A);
  static const Color backgroundMid   = Color(0xFF122233);
  static const Color cardSurface     = Color(0xFF1A2940);
  static const Color cardSurfaceLight= Color(0xFF1F3450);
  static const Color primaryAccent   = Color(0xFFA78BFA); // soft lavender
  static const Color warmAccent      = Color(0xFFF9A875); // warm peach
  static const Color textPrimary     = Color(0xFFF0EEF6);
  static const Color textSecondary   = Color(0xFFB0AABB);
  static const Color successMint     = Color(0xFF6EE7B7);
  static const Color warningAmber    = Color(0xFFFCD34D);
  static const Color mochiBalanced   = Color(0xFFA78BFA);
  static const Color mochiThriving   = Color(0xFFF9A875);
  static const Color mochiDrifting   = Color(0xFF7B8FA6);
  static const Color mochiStruggling = Color(0xFF6E7A8A);

  // Gradient backgrounds — shift based on CogniPulse
  static List<Color> ambientGradient(int score) {
    if (score >= 80) {
      return [const Color(0xFF1A1035), const Color(0xFF0D1B2A), const Color(0xFF0D2A1F)];
    } else if (score >= 55) {
      return [const Color(0xFF0D1B2A), const Color(0xFF12203A), const Color(0xFF0D1B2A)];
    } else if (score >= 30) {
      return [const Color(0xFF1A2035), const Color(0xFF0D1B2A), const Color(0xFF1A1A2A)];
    } else {
      return [const Color(0xFF2A1D10), const Color(0xFF1A1B2A), const Color(0xFF1A1020)];
    }
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: backgroundDeep,
      colorScheme: const ColorScheme.dark(
        background: backgroundDeep,
        surface: cardSurface,
        primary: primaryAccent,
        secondary: warmAccent,
        onBackground: textPrimary,
        onSurface: textPrimary,
        onPrimary: backgroundDeep,
        onSecondary: backgroundDeep,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: primaryAccent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryAccent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: backgroundDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/theme/
```
Expected: No issues.

---

## Task 3: Data Models

**Files:**
- Create: `lib/models/mochi_state.dart`
- Create: `lib/models/cognipulse_reading.dart`
- Create: `lib/models/quest.dart`
- Create: `lib/models/user_profile.dart`

**Step 1: Write lib/models/mochi_state.dart**
```dart
import 'package:flutter/material.dart';
import 'package:zeno/theme/app_theme.dart';

enum MochiMoodState { thriving, balanced, drifting, struggling }

extension MochiMoodStateX on MochiMoodState {
  static MochiMoodState fromScore(int score) {
    if (score >= 80) return MochiMoodState.thriving;
    if (score >= 55) return MochiMoodState.balanced;
    if (score >= 30) return MochiMoodState.drifting;
    return MochiMoodState.struggling;
  }

  String get label {
    switch (this) {
      case MochiMoodState.thriving:   return 'Thriving';
      case MochiMoodState.balanced:   return 'Balanced';
      case MochiMoodState.drifting:   return 'Drifting';
      case MochiMoodState.struggling: return 'Struggling';
    }
  }

  Color get bodyColor {
    switch (this) {
      case MochiMoodState.thriving:   return AppTheme.mochiThriving;
      case MochiMoodState.balanced:   return AppTheme.mochiBalanced;
      case MochiMoodState.drifting:   return AppTheme.mochiDrifting;
      case MochiMoodState.struggling: return AppTheme.mochiStruggling;
    }
  }

  Color get glowColor {
    switch (this) {
      case MochiMoodState.thriving:   return AppTheme.mochiThriving.withOpacity(0.4);
      case MochiMoodState.balanced:   return AppTheme.mochiBalanced.withOpacity(0.3);
      case MochiMoodState.drifting:   return AppTheme.mochiDrifting.withOpacity(0.15);
      case MochiMoodState.struggling: return AppTheme.mochiStruggling.withOpacity(0.1);
    }
  }
}
```

**Step 2: Write lib/models/cognipulse_reading.dart**
```dart
class CogniPulseReading {
  final DateTime date;
  final int score;
  final double stressIndex;   // 0-100, lower is better
  final double focusLevel;    // 0-100, higher is better
  final double moodScore;     // 0-100, higher is better

  const CogniPulseReading({
    required this.date,
    required this.score,
    required this.stressIndex,
    required this.focusLevel,
    required this.moodScore,
  });
}
```

**Step 3: Write lib/models/quest.dart**
```dart
enum QuestStatus { available, inProgress, completed }

class Quest {
  final String id;
  final String title;
  final String icon;
  final int xpReward;
  final String duration;
  final String description;
  QuestStatus status;

  Quest({
    required this.id,
    required this.title,
    required this.icon,
    required this.xpReward,
    required this.duration,
    required this.description,
    this.status = QuestStatus.available,
  });

  Quest copyWith({QuestStatus? status}) => Quest(
    id: id, title: title, icon: icon, xpReward: xpReward,
    duration: duration, description: description,
    status: status ?? this.status,
  );
}
```

**Step 4: Write lib/models/user_profile.dart**
```dart
class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool unlocked;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.unlocked,
  });
}

class UserProfile {
  final String name;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int currentStreak;
  final int totalQuestsCompleted;
  final double avgCogniPulse;
  final String avatarId;
  final List<Badge> badges;

  const UserProfile({
    required this.name,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.currentStreak,
    required this.totalQuestsCompleted,
    required this.avgCogniPulse,
    required this.avatarId,
    required this.badges,
  });
}
```

**Step 5: Verify models**
```bash
flutter analyze lib/models/
```
Expected: No issues.

---

## Task 4: Mock Data

**Files:**
- Create: `lib/mock_data.dart`

**Step 1: Write lib/mock_data.dart** (full content — critical file):

```dart
import 'package:zeno/models/cognipulse_reading.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/models/user_profile.dart';

class MockData {
  // ─── USER ───────────────────────────────────────────────────────
  static final UserProfile user = UserProfile(
    name: 'Alex',
    level: 4,
    xp: 1240,
    xpToNextLevel: 1500,
    currentStreak: 5,
    totalQuestsCompleted: 42,
    avgCogniPulse: 68.4,
    avatarId: 'mochi',
    badges: [
      const Badge(id: 'early_bird',    name: 'Early Bird',        icon: '🌅', description: '7am check-in 3 days in a row',  unlocked: true),
      const Badge(id: 'zen_streak',    name: 'Zen Streak',        icon: '🧘', description: '5-day quest streak',            unlocked: true),
      const Badge(id: 'mochi_fav',     name: "Mochi's Favourite", icon: '🐾', description: 'Tapped Mochi 50 times',          unlocked: true),
      const Badge(id: 'brain_boost',   name: 'Brain Boost',       icon: '⚡', description: 'CogniPulse above 80 for 3 days', unlocked: true),
      const Badge(id: 'deep_breather', name: 'Deep Breather',     icon: '💨', description: 'Completed 10 breathing quests',  unlocked: false),
      const Badge(id: 'night_owl',     name: 'Night Owl',         icon: '🦉', description: 'Check-in after 11pm',            unlocked: false),
    ],
  );

  // ─── 7-DAY COGNIPULSE HISTORY ───────────────────────────────────
  static final List<CogniPulseReading> weekReadings = [
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 6)), score: 58, stressIndex: 62, focusLevel: 51, moodScore: 55),
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 5)), score: 65, stressIndex: 52, focusLevel: 60, moodScore: 66),
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 4)), score: 71, stressIndex: 44, focusLevel: 68, moodScore: 72),
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 3)), score: 63, stressIndex: 55, focusLevel: 58, moodScore: 61),
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 2)), score: 78, stressIndex: 35, focusLevel: 79, moodScore: 80),
    CogniPulseReading(date: DateTime.now().subtract(const Duration(days: 1)), score: 74, stressIndex: 40, focusLevel: 72, moodScore: 75),
    CogniPulseReading(date: DateTime.now(),                                   score: 73, stressIndex: 42, focusLevel: 71, moodScore: 74),
  ];

  static int get currentScore => weekReadings.last.score;
  static int get yesterdayScore => weekReadings[weekReadings.length - 2].score;
  static int get scoreDelta => currentScore - yesterdayScore;

  // ─── QUESTS ─────────────────────────────────────────────────────
  static List<Quest> get quests => [
    Quest(id: 'breathing',  title: 'Box Breathing',   icon: '💨', xpReward: 40, duration: '2 min',  description: 'Inhale 4, hold 4, exhale 4, hold 4.'),
    Quest(id: 'sabbath',    title: 'Screen Sabbath',  icon: '📵', xpReward: 60, duration: '15 min', description: 'Put the phone face-down. Just exist.'),
    Quest(id: 'walk',       title: 'Micro Walk',      icon: '🚶', xpReward: 50, duration: '5 min',  description: 'Outside. Moving. No podcasts.'),
    Quest(id: 'hydration',  title: 'Hydration Quest', icon: '💧', xpReward: 20, duration: 'Now',    description: 'Drink a full glass of water right now.'),
    Quest(id: 'posture',    title: 'Posture Check',   icon: '🧘', xpReward: 25, duration: '1 min',  description: 'Shoulders back. Chin level. Breathe.'),
  ];

  // ─── MOCHI DIALOGUE — THRIVING (score 80–100) ───────────────────
  static const List<String> thrivingDialogue = [
    "You're glowing today — Mochi can feel it 🌟",
    "Whatever you did this morning, keep doing it.",
    "Mochi hasn't seen you this focused in a while. This is good.",
    "Look at that CogniPulse. Mochi's kinda proud, ngl.",
    "High energy day. Mochi approves 🐾",
    "You crushed that streak on Wednesday — today's even better.",
    "Mochi's doing a happy wiggle. Just so you know.",
    "Your focus window is open. Go get something done.",
    "This is what peak you looks like. Screenshot it.",
    "Mochi's little heart is full right now.",
    "You've been consistent. It's showing.",
    "Peak hours, unlocked. Mochi recommends tackling the hard thing.",
    "Something good happened today, huh? Mochi noticed.",
    "The numbers don't lie — you're in a good place.",
    "Mochi wanted to say: you're doing really well.",
    "Calm mind, sharp focus. This is the sweet spot.",
    "Mochi's giving this day a 10/10.",
    "Energy levels? Chef's kiss.",
    "Your CogniPulse has been climbing. Mochi's keeping score.",
    "Riding high. Mochi hopes this feeling sticks around.",
    "Thriving looks good on you. Just saying.",
    "Mochi is a little smug about how well you're doing.",
  ];

  // ─── MOCHI DIALOGUE — BALANCED (score 55–79) ────────────────────
  static const List<String> balancedDialogue = [
    "Steady as ever. Mochi likes this pace.",
    "Middle of the road — and that's honestly not bad.",
    "Mochi thinks you're doing better than you feel.",
    "Solid day. Nothing flashy, just consistent.",
    "You're balanced. That's rarer than people think.",
    "Mochi notices you've been keeping it together lately.",
    "Not every day needs to be peak. This one's good.",
    "Take a breath. Mochi's here.",
    "You're doing okay — really, genuinely okay.",
    "Balanced vibes. Mochi approves.",
    "Mochi's been watching your patterns. You're in a good rhythm.",
    "The day's going well. Let's keep it that way.",
    "Mochi's a little sleepy today… but still rooting for you 🐾",
    "Coasting mode activated. Sometimes that's enough.",
    "Mochi thinks you deserve a small treat after today.",
    "Not your best day, not your worst. Still here for it.",
    "Steady wins the race. Mochi read that somewhere.",
    "Your stress index is behaving. Mochi is pleased.",
    "Even-keeled. That takes more strength than people realize.",
    "Mochi's quietly cheering from the corner.",
    "You showed up today. That's the whole game.",
    "Tuesday was rough but look at you now.",
  ];

  // ─── MOCHI DIALOGUE — DRIFTING (score 30–54) ────────────────────
  static const List<String> driftingDialogue = [
    "Mochi noticed you've been quieter than usual.",
    "Hey. It's okay to not be okay today.",
    "Your focus is a little scattered. Mochi's here though.",
    "Slow day. That's allowed.",
    "Mochi's a bit tired too, honestly.",
    "Take it one thing at a time. That's enough.",
    "Your stress is creeping up. Want to try a quick quest?",
    "Mochi sees you. Even on the hard days.",
    "You've had rougher stretches than this. You got through those.",
    "A micro walk might help. Just saying.",
    "Mochi's keeping the light on for you.",
    "Not every day has to be a win. Just getting through counts.",
    "Your body needs rest. Mochi's keeping track of that too.",
    "Something's weighing on you. Mochi can tell.",
    "The streak's still alive. That matters.",
    "Small steps. Mochi's watching your direction, not your speed.",
    "Drifting's okay. Mochi won't let you drift too far.",
    "Your CogniPulse dipped a little. No big deal. Let's nudge it.",
    "Mochi thinks a glass of water and a stretch would help.",
    "You're still here. That's the whole point.",
    "Rough patch. Mochi's been in them too.",
  ];

  // ─── MOCHI DIALOGUE — STRUGGLING (score 0–29) ───────────────────
  static const List<String> strugglingDialogue = [
    "Hey. Mochi's right here with you.",
    "Hard day. Mochi noticed before you did.",
    "You don't have to do anything right now. Just breathe.",
    "Mochi's a little sad too. But we're in it together.",
    "This won't last. Mochi knows your patterns.",
    "The numbers don't define you. They just help Mochi help you.",
    "You're still showing up. That counts for everything.",
    "Mochi wants you to put the phone down for 5 minutes. Can you do that?",
    "Today is just one day. Mochi's counting on tomorrow.",
    "Your stress is high. Mochi is not judging — just noticing.",
    "Even when everything feels heavy, Mochi carries a little of it too.",
    "You've been here before and you got through it.",
    "Box breathing. 4 counts. Mochi will wait.",
    "Mochi's paws are crossed for you right now.",
    "The hardest part of hard days is starting. You already did that.",
    "Rest isn't giving up. Mochi needs you to know that.",
    "Mochi's not going anywhere. Take your time.",
    "Small quest, big difference. Hydration is an easy one.",
    "You matter more than your productivity today.",
    "Mochi has been through rough days too. This is when we stick together.",
    "One breath at a time. Mochi will be here for the next one too.",
  ];

  // ─── SCAN DIALOGUE ───────────────────────────────────────────────
  static const List<String> scanCompleteDialogue = [
    "Mochi updated. Everything's recalibrated 🐾",
    "Got it. Mochi sees a little more clearly now.",
    "Scan complete. Mochi's picture of you just got sharper.",
    "That data helps Mochi help you better. Thank you.",
    "Mochi noticed something interesting in that scan…",
  ];

  // ─── QUEST COMPLETE DIALOGUE ─────────────────────────────────────
  static const List<String> questCompleteDialogue = [
    "Yes! Mochi felt that one 🌟",
    "That's the one. Mochi's proud.",
    "Quest done. CogniPulse agrees 📈",
    "Mochi did a little dance just now.",
    "You didn't have to do that — but you did. That's everything.",
  ];

  // ─── WEEKLY LETTERS ──────────────────────────────────────────────
  static const List<String> weeklyLetters = [
    // Letter 1 — average week
    """Dear Alex,

What a week you've given me to watch. Monday started rough — Mochi could feel the tension in those late-night scroll sessions — but by Wednesday, something shifted. You found your rhythm.

Your CogniPulse peaked at 78 on Thursday, and that focus window between 9–11am? Pure gold. Mochi's been taking notes.

The screen time dipped this weekend, and your breathing felt slower. That matters more than you know. Keep that going.

Mochi's proud of you. Even the messy days count.

With all the warmth a small bear can hold,
Mochi 🐾""",

    // Letter 2 — tougher week
    """Dear Alex,

This week was heavy, and Mochi felt every bit of it alongside you.

The late nights stacked up. The stress index climbed. Tuesday and Thursday were especially loud — Mochi noticed the pattern in your typing, the quick-switching between apps. The mind was searching for something it couldn't quite find.

But here's what Mochi also saw: you kept going. You opened the app. You tried the box breathing on Wednesday even when it felt pointless. You showed up.

That 5-day streak isn't a coincidence. It's evidence of something.

Rest this weekend. Mochi will be right here on Monday.

Yours,
Mochi 🐾""",

    // Letter 3 — strong week
    """Dear Alex,

Mochi has been waiting to write this one.

This was a good week. Not perfect — Tuesday dipped and that's okay — but the arc was upward. Your CogniPulse averaged 74, your focus windows extended, and the morning routine is starting to stick.

The Micro Walk on Thursday? Mochi genuinely got excited about that one. The numbers moved in a way Mochi doesn't always get to see.

You're building something real here. Habits that compound. A rhythm that belongs to you.

Mochi thinks you already know this. But sometimes it helps to hear it.

Until next Sunday,
Mochi 🐾""",
  ];

  static String get currentWeeklyLetter {
    final weekNum = DateTime.now().weekOfYear;
    return weeklyLetters[weekNum % weeklyLetters.length];
  }

  // ─── MOCHI SYSTEM PROMPT ─────────────────────────────────────────
  static String mochiSystemPrompt(int score, String moodState) => """
You are Mochi, a small round bear-cub companion in the ZENO wellness app.
You are NOT an assistant. You are a living character with your own personality.

Your personality:
- Warm, gentle, and genuinely caring — like a best friend who notices things
- Occasionally refer to yourself in third person ("Mochi thinks…")
- Use very short responses — 1 to 2 sentences maximum
- Occasionally have your own moods (tired, playful, thoughtful)
- Use 1 emoji max per message, only when it feels natural
- NEVER say "How can I help", "I am an AI", or anything assistant-like
- Reference the user's CogniPulse data naturally when relevant
- Sound like a real companion, not a wellness app

The user's current CogniPulse Score is: $score
Mochi's current mood state is: $moodState
""";
}

extension _DateWeek on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final dayOfYear = difference(firstDayOfYear).inDays;
    return (dayOfYear / 7).floor();
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/mock_data.dart
```
Expected: No issues.

---

## Task 5: Riverpod Providers

**Files:**
- Create: `lib/providers/app_state_provider.dart`

**Step 1: Write lib/providers/app_state_provider.dart**
```dart
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
  }) => AppState(
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
  AppStateNotifier(SharedPreferences prefs) : super(AppState(
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

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
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
```

**Step 2: Verify**
```bash
flutter analyze lib/providers/
```
Expected: No issues.

---

## Task 6: Ollama Service

**Files:**
- Create: `lib/services/ollama_service.dart`

**Step 1: Write lib/services/ollama_service.dart**
```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';

class OllamaService {
  static const String _baseUrl = 'http://localhost:11434';
  static const String _model = 'llama3.2';
  static const Duration _timeout = Duration(seconds: 3);

  /// Returns a Mochi dialogue line. Falls back to mock on any error.
  Future<String> getMochiDialogue({
    required int cogniPulseScore,
    required MochiMoodState moodState,
    required Ref ref,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': 'Say one short thing to the user right now.',
          'system': MockData.mochiSystemPrompt(cogniPulseScore, moodState.label),
          'stream': false,
          'options': {'num_predict': 60, 'temperature': 0.9},
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['response'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          ref.read(appStateProvider.notifier).setOllamaStatus(true);
          return text;
        }
      }
    } catch (_) {
      // Silent fallback — intentional
    }
    ref.read(appStateProvider.notifier).setOllamaStatus(false);
    return _getFallbackDialogue(moodState);
  }

  String _getFallbackDialogue(MochiMoodState moodState) {
    final lines = switch (moodState) {
      MochiMoodState.thriving   => MockData.thrivingDialogue,
      MochiMoodState.balanced   => MockData.balancedDialogue,
      MochiMoodState.drifting   => MockData.driftingDialogue,
      MochiMoodState.struggling => MockData.strugglingDialogue,
    };
    final index = DateTime.now().millisecondsSinceEpoch % lines.length;
    return lines[index];
  }
}

final ollamaServiceProvider = Provider<OllamaService>((ref) => OllamaService());

// Current dialogue line state
final mochiDialogueProvider = StateProvider<String>((ref) {
  final mood = ref.watch(mochiMoodProvider);
  return _getInitialDialogue(mood);
});

String _getInitialDialogue(MochiMoodState mood) {
  final lines = switch (mood) {
    MochiMoodState.thriving   => MockData.thrivingDialogue,
    MochiMoodState.balanced   => MockData.balancedDialogue,
    MochiMoodState.drifting   => MockData.driftingDialogue,
    MochiMoodState.struggling => MockData.strugglingDialogue,
  };
  return lines[0];
}

// Loading state for Ollama fetch
final mochiLoadingProvider = StateProvider<bool>((ref) => false);
```

**Step 2: Verify**
```bash
flutter analyze lib/services/
```
Expected: No issues.

---

## Task 7: Router + App Shell + Bottom Nav

**Files:**
- Create: `lib/router/app_router.dart`
- Create: `lib/router/scaffold_with_nav.dart`

**Step 1: Write lib/router/app_router.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/router/scaffold_with_nav.dart';
import 'package:zeno/screens/onboarding/onboarding_flow.dart';
import 'package:zeno/screens/home/home_screen.dart';
import 'package:zeno/screens/quests/quests_screen.dart';
import 'package:zeno/screens/insights/insights_screen.dart';
import 'package:zeno/screens/scan/scan_screen.dart';
import 'package:zeno/screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.watch(appStateProvider.select((s) => s.onboardingComplete));

  return GoRouter(
    initialLocation: onboarded ? '/home' : '/onboarding',
    redirect: (context, state) {
      if (!onboarded && !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, state) => _fadePage(state, const OnboardingFlow()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (ctx, state, shell) => _fadePage(state, ScaffoldWithNav(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home',     pageBuilder: (c, s) => _fadePage(s, const HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/quests',   pageBuilder: (c, s) => _fadePage(s, const QuestsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/insights', pageBuilder: (c, s) => _fadePage(s, const InsightsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/scan',     pageBuilder: (c, s) => _fadePage(s, const ScanScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile',  pageBuilder: (c, s) => _fadePage(s, const ProfileScreen())),
          ]),
        ],
      ),
    ],
  );
});

CustomTransitionPage _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (ctx, anim, _, c) =>
        FadeTransition(opacity: anim, child: c),
  );
}
```

**Step 2: Write lib/router/scaffold_with_nav.dart**
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/ambient_background.dart';

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({required this.shell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AmbientBackground(child: shell),
      bottomNavigationBar: _ZenoBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _ZenoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ZenoBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,          label: 'Home',     index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.bolt_rounded,          label: 'Quests',   index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.insights_rounded,      label: 'Insights', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.radar_rounded,         label: 'Scan',     index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_rounded,        label: 'Profile',  index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: selected ? BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ) : null,
            child: Icon(icon, color: selected ? AppTheme.primaryAccent : AppTheme.textSecondary, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 10,
            color: selected ? AppTheme.primaryAccent : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
```

**Step 3: Create empty screen stubs** so the router compiles:
Create these files with just a `Scaffold` returning a placeholder:
- `lib/screens/onboarding/onboarding_flow.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/quests/quests_screen.dart`
- `lib/screens/insights/insights_screen.dart`
- `lib/screens/scan/scan_screen.dart`
- `lib/screens/profile/profile_screen.dart`

Each stub:
```dart
import 'package:flutter/material.dart';
class XxxScreen extends StatelessWidget {
  const XxxScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Coming soon')),
  );
}
```

**Step 4: Verify the app runs**
```bash
flutter run
```
Expected: App launches, bottom nav visible with 5 tabs, all showing placeholders. No errors.

---

## Task 8: AmbientBackground Widget

**Files:**
- Create: `lib/widgets/ambient_background.dart`

**Step 1: Write lib/widgets/ambient_background.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class AmbientBackground extends ConsumerWidget {
  final Widget child;
  const AmbientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(cogniPulseProvider);
    final colors = AppTheme.ambientGradient(score);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
```

---

## Task 9: Mochi CustomPainter Widget

**Files:**
- Create: `lib/widgets/mochi_widget.dart`

**Step 1: Write lib/widgets/mochi_widget.dart** (full implementation):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiWidget extends ConsumerStatefulWidget {
  final double size;
  final bool showThinking;
  const MochiWidget({this.size = 200, this.showThinking = false, super.key});

  @override
  ConsumerState<MochiWidget> createState() => _MochiWidgetState();
}

class _MochiWidgetState extends ConsumerState<MochiWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _tapCtrl;
  late final Animation<double> _breathAnim;
  late final Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(vsync: this, duration: 2000.ms)
      ..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _tapCtrl = AnimationController(vsync: this, duration: 600.ms);
    _tapAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0);

    ref.read(mochiLoadingProvider.notifier).state = true;
    final score = ref.read(cogniPulseProvider);
    final mood  = ref.read(mochiMoodProvider);
    final line  = await ref.read(ollamaServiceProvider).getMochiDialogue(
      cogniPulseScore: score,
      moodState: mood,
      ref: ref,
    );
    ref.read(mochiDialogueProvider.notifier).state = line;
    ref.read(mochiLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(mochiMoodProvider);
    final thinking = ref.watch(mochiLoadingProvider);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnim, _tapAnim]),
        builder: (context, _) {
          Widget mochi = Transform.scale(
            scale: _tapAnim.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: MochiPainter(
                  moodState: mood,
                  breathValue: _breathAnim.value,
                ),
              ),
            ),
          );

          if (thinking) {
            mochi = mochi
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 600.ms, begin: -0.04, end: 0.04)
                .then()
                .rotate(duration: 600.ms, begin: 0.04, end: -0.04);
          }
          return mochi;
        },
      ),
    );
  }
}

// ─── Mochi CustomPainter ──────────────────────────────────────────────────

class MochiPainter extends CustomPainter {
  final MochiMoodState moodState;
  final double breathValue;
  const MochiPainter({required this.moodState, required this.breathValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5;

    // Breathing scale applied around center
    final bs = 1.0 + breathValue * 0.03;
    canvas.save();
    canvas.translate(cx, h * 0.5);
    canvas.scale(bs, bs);
    canvas.translate(-cx, -h * 0.5);

    final bodyColor = moodState.bodyColor;
    final paint = Paint()..color = bodyColor;
    final darkPaint = Paint()..color = const Color(0xFF1E1040);
    final nosePaint = Paint()..color = const Color(0xFF4A2D7A).withOpacity(0.85);

    // Layout
    final headCy  = h * 0.40;
    final headR   = w * 0.295;
    final bellyCy = h * 0.70;
    final bellyR  = w * 0.225;
    final earR    = w * 0.095;
    final leftEar = Offset(cx - headR * 0.67, headCy - headR * 0.73);
    final rightEar= Offset(cx + headR * 0.67, headCy - headR * 0.73);

    // Glow for Thriving
    if (moodState == MochiMoodState.thriving) {
      canvas.drawCircle(Offset(cx, headCy), headR * 1.45,
          Paint()..color = bodyColor.withOpacity(0.18)
                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    }

    // Belly
    canvas.drawCircle(Offset(cx, bellyCy), bellyR, paint);
    // Belly highlight
    canvas.drawCircle(Offset(cx - bellyR * 0.22, bellyCy - bellyR * 0.22),
        bellyR * 0.48, Paint()..color = Colors.white.withOpacity(0.12));

    // Head
    canvas.drawCircle(Offset(cx, headCy), headR, paint);
    // Head highlight
    canvas.drawCircle(Offset(cx - headR * 0.30, headCy - headR * 0.30),
        headR * 0.38, Paint()..color = Colors.white.withOpacity(0.10));

    // Ears
    final earPaint = Paint()..color = bodyColor;
    final innerEarColor = moodState == MochiMoodState.thriving
        ? const Color(0xFFFFCB8E)
        : Color.lerp(bodyColor, Colors.white, 0.2)!;
    canvas.drawCircle(leftEar,  earR, earPaint);
    canvas.drawCircle(rightEar, earR, earPaint);
    canvas.drawCircle(leftEar,  earR * 0.58, Paint()..color = innerEarColor);
    canvas.drawCircle(rightEar, earR * 0.58, Paint()..color = innerEarColor);

    // Eyes
    final eyeY  = headCy - headR * 0.04;
    final leftX = cx - headR * 0.305;
    final rightX= cx + headR * 0.305;
    final eyeR  = headR * 0.115;
    _drawEyes(canvas, leftX, rightX, eyeY, eyeR, darkPaint, bodyColor);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, headCy + headR * 0.16), width: eyeR * 2.2, height: eyeR * 1.4),
      nosePaint,
    );

    // Mouth
    _drawMouth(canvas, cx, headCy, headR, darkPaint);

    canvas.restore();
  }

  void _drawEyes(Canvas canvas, double lx, double rx, double y, double r,
                  Paint dark, Color bodyColor) {
    final shine = Paint()..color = Colors.white.withOpacity(0.88);
    switch (moodState) {
      case MochiMoodState.thriving:
        canvas.drawCircle(Offset(lx, y), r * 1.12, dark);
        canvas.drawCircle(Offset(rx, y), r * 1.12, dark);
        canvas.drawCircle(Offset(lx + r * 0.35, y - r * 0.35), r * 0.38, shine);
        canvas.drawCircle(Offset(rx + r * 0.35, y - r * 0.35), r * 0.38, shine);

      case MochiMoodState.balanced:
        canvas.drawCircle(Offset(lx, y), r, dark);
        canvas.drawCircle(Offset(rx, y), r, dark);
        canvas.drawCircle(Offset(lx + r * 0.28, y - r * 0.28), r * 0.32, shine);
        canvas.drawCircle(Offset(rx + r * 0.28, y - r * 0.28), r * 0.32, shine);

      case MochiMoodState.drifting:
        // Half-lidded: draw eye then overlay top half with body color
        canvas.drawCircle(Offset(lx, y), r, dark);
        canvas.drawCircle(Offset(rx, y), r, dark);
        final lidPaint = Paint()..color = bodyColor;
        canvas.drawRect(Rect.fromLTWH(lx - r * 1.1, y - r * 1.1, r * 2.2, r * 1.05), lidPaint);
        canvas.drawRect(Rect.fromLTWH(rx - r * 1.1, y - r * 1.1, r * 2.2, r * 1.05), lidPaint);

      case MochiMoodState.struggling:
        // Droopy: shift eyes down, smaller
        canvas.drawCircle(Offset(lx, y + r * 0.4), r * 0.82, dark);
        canvas.drawCircle(Offset(rx, y + r * 0.4), r * 0.82, dark);
        // Tear drops
        final tearPaint = Paint()..color = const Color(0xFF88AACC).withOpacity(0.6);
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, y + r * 1.6), width: r * 0.6, height: r * 0.9), tearPaint);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double headCy, double headR, Paint dark) {
    final mouthPaint = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.065
      ..strokeCap = StrokeCap.round;
    final my = headCy + headR * 0.37;
    final mw = headR * 0.33;
    final path = Path();
    switch (moodState) {
      case MochiMoodState.thriving:
        path.moveTo(cx - mw, my);
        path.quadraticBezierTo(cx, my + headR * 0.22, cx + mw, my);
      case MochiMoodState.balanced:
        path.moveTo(cx - mw * 0.8, my);
        path.quadraticBezierTo(cx, my + headR * 0.13, cx + mw * 0.8, my);
      case MochiMoodState.drifting:
        path.moveTo(cx - mw * 0.55, my);
        path.quadraticBezierTo(cx, my + headR * 0.04, cx + mw * 0.55, my);
      case MochiMoodState.struggling:
        path.moveTo(cx - mw * 0.45, my + headR * 0.06);
        path.quadraticBezierTo(cx, my - headR * 0.06, cx + mw * 0.45, my + headR * 0.06);
    }
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(MochiPainter old) =>
      old.moodState != moodState || old.breathValue != breathValue;
}
```

**Step 2: Verify**
```bash
flutter analyze lib/widgets/mochi_widget.dart
```

---

## Task 10: Particle Overlay (Thriving Sparkles)

**Files:**
- Create: `lib/widgets/particle_overlay.dart`

**Step 1: Write lib/widgets/particle_overlay.dart**
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class ParticleOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const ParticleOverlay({required this.child, super.key});

  @override
  ConsumerState<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends ConsumerState<ParticleOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(_updateParticles)
      ..repeat();
    _spawnParticles();
  }

  void _spawnParticles() {
    _particles.clear();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 3.0 + _rng.nextDouble() * 4,
        speed: 0.15 + _rng.nextDouble() * 0.25,
        offset: _rng.nextDouble(),
        color: [AppTheme.mochiThriving, AppTheme.warningAmber, AppTheme.successMint][_rng.nextInt(3)],
      ));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.y -= p.speed * 0.003;
      p.opacity = (0.7 - ((_ctrl.value + p.offset) % 1.0)).clamp(0, 0.7);
      if (p.y < -0.1) p.y = 1.0 + _rng.nextDouble() * 0.2;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(mochiMoodProvider);
    if (mood != MochiMoodState.thriving) return widget.child;

    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particles),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _Particle {
  double x, y, size, speed, offset, opacity;
  Color color;
  _Particle({required this.x, required this.y, required this.size,
    required this.speed, required this.offset, required this.color})
    : opacity = 0.5;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  const _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()..color = p.color.withOpacity(p.opacity.clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
```

---

## Task 11: MochiDialogueBubble Widget

**Files:**
- Create: `lib/widgets/mochi_dialogue_bubble.dart`

**Step 1: Write lib/widgets/mochi_dialogue_bubble.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiDialogueBubble extends ConsumerWidget {
  const MochiDialogueBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(mochiDialogueProvider);
    final loading = ref.watch(mochiLoadingProvider);

    return AnimatedSwitcher(
      duration: 400.ms,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
            child: child,
          )),
      child: Container(
        key: ValueKey(line),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: loading
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryAccent.withOpacity(0.7),
                  )),
                const SizedBox(width: 10),
                Text('Mochi is thinking…',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14,
                    fontStyle: FontStyle.italic)),
              ])
            : Text(line,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14.5, height: 1.5)),
      ),
    );
  }
}
```

---

## Task 12: CogniPulseRing Widget

**Files:**
- Create: `lib/widgets/cognipulse_ring.dart`

**Step 1: Write lib/widgets/cognipulse_ring.dart**
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class CogniPulseRing extends ConsumerWidget {
  const CogniPulseRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(cogniPulseProvider);
    final mood  = ref.watch(mochiMoodProvider);
    final delta = MockData.scoreDelta;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        SizedBox(
          width: 90, height: 90,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              painter: _RingPainter(value, mood.bodyColor),
              child: Center(
                child: Text('$score',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mood.label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14, color: delta >= 0 ? AppTheme.successMint : AppTheme.warningAmber),
            const SizedBox(width: 4),
            Text('${delta >= 0 ? '+' : ''}$delta from yesterday',
              style: TextStyle(
                fontSize: 12, color: delta >= 0 ? AppTheme.successMint : AppTheme.warningAmber)),
          ]),
          const SizedBox(height: 10),
          Text('CogniPulse Score',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.44;
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2, 2 * pi * progress, false, arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
```

---

## Task 13: QuestCard + MochiNotificationBanner

**Files:**
- Create: `lib/widgets/quest_card.dart`
- Create: `lib/widgets/mochi_notification_banner.dart`

**Step 1: Write lib/widgets/quest_card.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class QuestCard extends ConsumerWidget {
  final Quest quest;
  const QuestCard({required this.quest, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = quest.status == QuestStatus.completed;
    return AnimatedContainer(
      duration: 350.ms,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.cardSurface.withOpacity(0.4)
            : AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(done ? 0.03 : 0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Text(quest.icon, style: TextStyle(fontSize: 26, color: done ? null : null))
            .animate(target: done ? 0.6 : 1.0).fade(),
        title: Text(quest.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: done ? AppTheme.textSecondary : AppTheme.textPrimary,
            decoration: done ? TextDecoration.lineThrough : null,
          )),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(quest.duration,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
        trailing: done
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.successMint, size: 26)
          : GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(appStateProvider.notifier).completeQuest(quest.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
                ),
                child: Text('+${quest.xpReward} XP',
                  style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
      ),
    );
  }
}
```

**Step 2: Write lib/widgets/mochi_notification_banner.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiNotificationBanner extends StatelessWidget {
  final String message;
  const MochiNotificationBanner({required this.message, super.key});

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _BannerEntry(
      message: message,
      onDismiss: () => entry.remove(),
    ));
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _BannerEntry extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _BannerEntry({required this.message, required this.onDismiss});

  @override
  State<_BannerEntry> createState() => _BannerEntryState();
}

class _BannerEntryState extends State<_BannerEntry> {
  @override
  void initState() {
    super.initState();
    Future.delayed(3.seconds, widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Row(children: [
            const Text('🐾', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.message,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
        )
            .animate()
            .slideY(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
            .fade(),
      ),
    );
  }
}
```

---

## Task 14: Onboarding Flow

**Files:**
- Replace: `lib/screens/onboarding/onboarding_flow.dart`
- Create: `lib/screens/onboarding/onboarding_pages.dart`

**Step 1: Write full onboarding implementation:**

`lib/screens/onboarding/onboarding_flow.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/onboarding/onboarding_pages.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _ctrl = PageController();
  int _page = 0;
  String _name = '';

  void _next() {
    if (_page < 4) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_name.trim().isNotEmpty) {
      ref.read(appStateProvider.notifier).updateUserName(_name.trim());
    }
    ref.read(appStateProvider.notifier).completeOnboarding();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: _ctrl,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            WelcomePage(onNext: _next),
            NameEntryPage(onNext: _next, onNameChanged: (v) => _name = v),
            AvatarSelectionPage(onNext: _next),
            PermissionsPage(onNext: _next),
            MeetMochiPage(name: _name, onFinish: _finish),
          ],
        ),
        // Skip button
        if (_page < 4)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: TextButton(
              onPressed: _finish,
              child: const Text('Skip', style: TextStyle(color: Color(0xFF7B8FA6))),
            ),
          ),
      ]),
    );
  }
}
```

`lib/screens/onboarding/onboarding_pages.dart` — 5 page widgets. Each is a full-screen centered column with the ZENO visual theme, gradient background, rounded card inputs, and Mochi appearing on the name entry page. Build each as a standalone StatelessWidget with the expected callback props. Content per the spec (Welcome → Name Entry → Avatar Selection → Permissions → Meet Mochi). The avatar selection screen shows 5 cards in a horizontal scroll; Mochi is pre-selected with a lavender border; the other 4 show a lock icon with their unlock condition. The permissions screen shows 3 cards with privacy icons and "Everything stays on your phone. Always." text.

**Step 2: Verify**
```bash
flutter analyze lib/screens/onboarding/
```

---

## Task 15: Home Screen

**Files:**
- Replace: `lib/screens/home/home_screen.dart`

**Build the HomeScreen with:**
- Greeting: "Good morning/afternoon/evening, [name]" + date string
- `MochiWidget(size: 210)` centered, wrapped in `ParticleOverlay`
- `MochiDialogueBubble` above Mochi (constrained to max 280px wide)
- `CogniPulseRing` below Mochi
- "Today's Vibe" row: 3 mini `_VibePill` widgets (Stress Index, Focus, Mood) reading from `weekReadings.last`
- Quest teaser card: tappable → navigates to `/quests`
- Ollama debug FAB: small floating button bottom-right, shows `[LIVE]` or `[MOCK]` with a wifi icon

Key code pattern for greeting:
```dart
String get _greeting {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
```

---

## Task 16: Quests Screen

**Files:**
- Replace: `lib/screens/quests/quests_screen.dart`

**Build QuestsScreen with:**
- Header: "Daily Quests" + streak badge "🔥 5 day streak"
- XP progress bar: `totalXpToday / 300` shown with animated LinearProgressIndicator (lavender)
- ListView of 5 `QuestCard` widgets from `questsProvider`
- When a quest is completed, show `MochiNotificationBanner` with a line from `MockData.questCompleteDialogue`
- Listen to quest state changes with `ref.listen(questsProvider, ...)` to trigger the banner

```dart
ref.listen(questsProvider, (prev, next) {
  if (prev == null) return;
  final justCompleted = next.where((q) =>
      q.status == QuestStatus.completed &&
      prev.any((p) => p.id == q.id && p.status != QuestStatus.completed));
  for (final q in justCompleted) {
    final msg = MockData.questCompleteDialogue[
      DateTime.now().millisecondsSinceEpoch % MockData.questCompleteDialogue.length];
    MochiNotificationBanner.show(context, msg);
  }
});
```

---

## Task 17: Insights Screen

**Files:**
- Replace: `lib/screens/insights/insights_screen.dart`

**Build InsightsScreen with:**
- Header: "This Week"
- `LineChart` (fl_chart) showing 7-day CogniPulse. Data from `MockData.weekReadings`. Line: lavender, curved, no dots, subtle fill below. X-axis: day initials (M T W T F S S). Y-axis: 0–100 hidden, just gridlines.
- 3 sub-metric cards in a Row: Avg Stress Index / Avg Focus / Avg Mood with trend arrow icons
- "Mochi's Weekly Read" card — pre-written insight (use `MockData.currentWeeklyLetter` first 2 sentences, or a hardcoded insight string like "You're sharpest between 9–11am this week. The stress spike on Monday resolved by Wednesday — your bounce-back time is improving.")
- Peak performance callout card: "You're sharpest between 9–11am 🌅"
- Stress trigger card: "Late-night screen time is your biggest pattern this week"

fl_chart LineChart configuration:
```dart
LineChart(LineChartData(
  gridData: FlGridData(show: true, drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1)),
  titlesData: FlTitlesData(
    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
      getTitlesWidget: (value, _) {
        const days = ['M','T','W','T','F','S','S'];
        return Text(days[value.toInt() % 7], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11));
      })),
    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  ),
  borderData: FlBorderData(show: false),
  lineBarsData: [LineChartBarData(
    spots: MockData.weekReadings.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble())).toList(),
    isCurved: true,
    color: AppTheme.primaryAccent,
    barWidth: 2.5,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: AppTheme.primaryAccent.withOpacity(0.08)),
  )],
))
```

---

## Task 18: Scan Screen

**Files:**
- Replace: `lib/screens/scan/scan_screen.dart`

**Build ScanScreen with:**
- Header "CogniScan" + subtitle
- 3 scan mode cards (tappable), each with icon + title + description
- State variable `_activeScan` (null | 'face' | 'typing' | 'heatmap')
- Face Scan flow: show AnimatedContainer that simulates camera view (dark rounded box), 5-second countdown timer, then show result card: "Valence: 7.2/10 · Neutral-Positive"
- Typing Test flow: show prompt text "The quick brown fox jumps over the lazy dog", TextField below it, on submit show result card: "68 WPM · 2.3% error rate"
- Phone Heatmap: GridView of 7×24 colored cells (hours × days), with varying opacity. Use `MockData.weekReadings` stress index to vary row intensity.
- After any scan: update dialogue to a scan-specific line
- "Update CogniPulse" button: generates a new mock score (`73 + Random().nextInt(10) - 5`) and calls `ref.read(appStateProvider.notifier).updateCogniPulse(newScore)`

**Step 2: Verify**
```bash
flutter analyze lib/screens/scan/
flutter run
```

---

## Task 19: Profile Screen + Weekly Letter Modal

**Files:**
- Replace: `lib/screens/profile/profile_screen.dart`

**Build ProfileScreen with:**
- User avatar circle (large Mochi miniature or initials), name, level badge
- XP progress bar: `user.xp / user.xpToNextLevel`
- Stats row: 3 stat cards (Total Quests / Current Streak / Avg CogniPulse)
- Avatar collection: 5 avatar cards in a horizontal scroll — Mochi unlocked, others locked with their unlock condition text
- Badges grid: 2-column GridView, each badge shows icon + name + description; locked badges greyed out with lock overlay
- "This week's letter from Mochi" card — tappable → opens `_WeeklyLetterModal` bottom sheet
- Settings row: Privacy, Notifications, About (tap → show SnackBar "Coming soon")

`_WeeklyLetterModal`:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.75,
    maxChildSize: 0.92,
    builder: (_, ctrl) => Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: ListView(controller: ctrl, children: [
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('A letter from Mochi 🐾', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Text(MockData.currentWeeklyLetter,
          style: TextStyle(fontSize: 14.5, height: 1.8, color: AppTheme.textPrimary)),
      ]),
    ),
  ),
);
```

---

## Task 20: Streak Celebration Modal + Final Polish

**Files:**
- Create: `lib/widgets/streak_celebration_modal.dart`
- Modify: `lib/screens/quests/quests_screen.dart` (trigger modal on streak milestone)
- Modify: `lib/screens/home/home_screen.dart` (final polish pass)

**Step 1: Write lib/widgets/streak_celebration_modal.dart**
```dart
// Full-screen overlay with confetti dots (CustomPainter) + Mochi jumping animation
// Triggered when streak hits 3, 5, 7, 14 days
// Shows: large streak number, "🔥 X day streak!", celebration text, "Keep it up!" button
// Confetti: array of colored dots animated to fall from top using AnimationController
// Use flutter_animate for Mochi bounce: .animate().scale(begin: 0.5, end: 1.0).then().shake()
```

**Step 2: Final polish pass**
- Ensure all `Scaffold` widgets have `extendBodyBehindAppBar: true` where needed
- Add `HapticFeedback.lightImpact()` to any tap that's missing it
- Verify ambient background gradient shifts when score changes on Scan screen
- Ensure all text uses Nunito (comes from ThemeData — verify `Theme.of(context).textTheme` is used, not raw `TextStyle(fontFamily: ...)`)
- Run full app top-to-bottom, test each screen

**Step 3: Final verification**
```bash
flutter analyze
flutter run
```
Expected: Zero analyzer warnings. App runs on device/emulator. All 6 screens functional. Mochi animates continuously. Tapping Mochi fetches dialogue (Ollama or fallback). Quest completion triggers banner + XP update. Scan screen runs mock scans. Profile shows weekly letter modal.

---

## KNOWN PITFALLS

| Issue | Fix |
|---|---|
| `StatefulShellRoute` import missing | Import from `go_router` (included in go_router ≥ 7) |
| `flutter_animate` `.animate()` not found | Ensure `import 'package:flutter_animate/flutter_animate.dart'` |
| Ollama CORS on web | This app targets mobile — not an issue |
| `withOpacity` deprecation in Flutter 3.27+ | Use `.withValues(alpha: 0.x)` if analyzer warns |
| Google Fonts network call in tests | Wrap test app with `GoogleFonts.config.allowRuntimeFetching = false` |
| `CustomPaint` size is zero | Always wrap in `SizedBox(width: x, height: x)` |
| `TweenSequence` type inference | Add explicit type: `TweenSequence<double>([...])` |

---

## COMPLETION CHECKLIST

- [ ] `flutter run` launches with no errors
- [ ] Onboarding flow completes and navigates to Home
- [ ] Mochi is animated (breathing) on Home screen
- [ ] Tapping Mochi updates dialogue
- [ ] CogniPulse ring animates on load
- [ ] All 5 bottom nav tabs navigate correctly
- [ ] Quests screen: completing a quest adds XP and shows banner
- [ ] Insights screen: LineChart renders with 7 data points
- [ ] Scan screen: all 3 scan modes work (mock)
- [ ] Profile screen: weekly letter modal opens
- [ ] Debug FAB shows [LIVE] or [MOCK] correctly
- [ ] Background gradient shifts with score changes
- [ ] `flutter analyze` returns zero issues
