import 'package:zeno/models/quest.dart';

class MockData {
  // ─── QUEST CATALOG ──────────────────────────────────────────────
  // Definitions only; which ones are done today comes from the XP ledger.
  static List<Quest> get quests => [
    Quest(id: 'breathing',  title: 'Box Breathing',   icon: '💨', xpReward: 40, duration: '2 min',  description: 'Inhale 4, hold 4, exhale 4, hold 4.'),
    Quest(id: 'sabbath',    title: 'Screen Sabbath',  icon: '📵', xpReward: 60, duration: '15 min', description: 'Put the phone face-down. Just exist.'),
    Quest(id: 'walk',       title: 'Micro Walk',      icon: '🚶', xpReward: 50, duration: '5 min',  description: 'Outside. Moving. No podcasts.'),
    Quest(id: 'hydration',  title: 'Hydration Quest', icon: '💧', xpReward: 20, duration: 'Now',    description: 'Drink a full glass of water right now.'),
    Quest(id: 'posture',    title: 'Posture Check',   icon: '🧘', xpReward: 25, duration: '1 min',  description: 'Shoulders back. Chin level. Breathe.'),
    Quest(id: 'focus_quest',  title: 'Focus Quest',   icon: '👁', xpReward: 45, duration: '2 min',  description: 'Play Focus Flicker to sharpen your attention.'),
    Quest(id: 'memory_quest', title: 'Memory Quest',  icon: '🌸', xpReward: 35, duration: '2 min',  description: 'Play Memory Garden to exercise your recall.'),
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
    """Dear Alex,

What a week you've given me to watch. Monday started rough — Mochi could feel the tension in those late-night scroll sessions — but by Wednesday, something shifted. You found your rhythm.

Your CogniPulse peaked at 78 on Thursday, and that focus window between 9–11am? Pure gold. Mochi's been taking notes.

The screen time dipped this weekend, and your breathing felt slower. That matters more than you know. Keep that going.

Mochi's proud of you. Even the messy days count.

With all the warmth a small bear can hold,
Mochi 🐾""",

    """Dear Alex,

This week was heavy, and Mochi felt every bit of it alongside you.

The late nights stacked up. The stress index climbed. Tuesday and Thursday were especially loud — Mochi noticed the pattern in your typing, the quick-switching between apps. The mind was searching for something it couldn't quite find.

But here's what Mochi also saw: you kept going. You opened the app. You tried the box breathing on Wednesday even when it felt pointless. You showed up.

That 5-day streak isn't a coincidence. It's evidence of something.

Rest this weekend. Mochi will be right here on Monday.

Yours,
Mochi 🐾""",

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
