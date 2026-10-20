# PRD traceability

Every requirement in `ZENO_PRD.docx` (v1.0, March 2026), what this build does about it, where the code is, and which test checks it. Test names are quoted from the test files so they can be searched.

Status key: **Done** means built and working as the PRD describes. **Changed** means built, but differently from the PRD, with the reason given. **Partial** means some of it is built. **Not built** means it isn't in this build.

Summary: of the 39 rows below, 18 are Done, 6 Changed, 7 Partial and 8 Not built. The five out-of-scope items are listed separately and none of them were built.

## 5.1 Mochi, the living companion

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 1 | Four mood states mapped to CogniPulse bands | Done | `models/mochi_state.dart` (`fromScore`: 80/55/30) | `mochi_state_test.dart`: "Mochi breathes faster when thriving and slower when struggling" |
| 2 | Mochi always animated, look changes with mood | Done | `widgets/mochi_widget.dart`, `widgets/particle_overlay.dart` | `app_smoke_test.dart`: "first launch: splash, onboarding, skip, then home" (renders Mochi) |
| 3 | Personality growth over 30 days (night owl, achiever, anxious) | Partial | `providers/mochi_personality_provider.dart` reacts to mood, time of day, streak and score change. There's no 30-day learning and no archetypes. | none |
| 4 | Bad days (Mochi has its own moods) | Not built | | |
| 5 | Memory system, references past events | Partial | `services/game_context_builder.dart` and `face_scan_context_builder.dart` put recent games and the latest scan into the Ollama prompt; the weekly letter names the user's best day. | `weekly_letter_test.dart`: "the letter is written from the week…" |
| 6 | Mochi playdates (social) | Not built | Social features are out of MVP scope (PRD §8). | |
| 7 | Weekly letter in Mochi's voice | Changed | `services/weekly_letter.dart`, opened from Profile. It's written by rules from the user's real week, not by an LLM, and is available any day rather than delivered on Sunday (there are no notifications). | `weekly_letter_test.dart`: "with no check-ins the letter says so instead of inventing a week"; `profile_screen_test.dart`: "the weekly letter is written from this week, not a template" |

## 5.2 CogniPulse score

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 8 | 0 to 100 score fused from weighted signals | Done | `services/cognipulse_engine.dart` | `cognipulse_engine_test.dart`: "all four measured signals plus baseline use PRD weights", "weights are renormalised over the signals measured today" |
| 9 | Phone usage patterns, 30% | Not built | Needs Android usage-stats permission and a background service. The breakdown sheet and About sheet say it isn't measured. | `cognipulse_engine_test.dart`: "phone usage is always listed as not measured"; `profile_settings_test.dart`: "About says what is and is not measured" |
| 10 | Typing behaviour, 35% | Changed | `services/typing_analyzer.dart`, `widgets/typing_check_in.dart`. An active typing check-in on the Scan tab instead of a system keyboard layer. Same features: speed, accuracy, backspaces, pauses. | `typing_analyzer_test.dart` (6 tests); `typing_check_in_test.dart`: "typing the sentence records a typing reading", "pasting the sentence is rejected" |
| 11 | Facial micro-expression scan, 20%, 5 s, on-device | Changed | `screens/scan/scan_screen.dart`, `services/face_scan_analyzer.dart`. Google ML Kit instead of MediaPipe; still on-device and 5 seconds. A hand-written formula, not a trained model, turns ML Kit's probabilities into a score. | `face_scan_analyzer_test.dart` (6 tests); `face_scan_entry_test.dart` |
| 12 | Self-reported mood, 15% | Done | `widgets/quick_mood_log.dart` on Home | `score_and_mood_test.dart`: "tapping a mood logs it and moves the score"; `app_state_test.dart`: "a mood check-in moves the score and gives XP only once a day" |
| 13 | Game play as a signal | Changed (addition) | Not in the PRD. `services/game_feature_pipeline.dart` at weight 0.15. | `game_feature_pipeline_test.dart` (11 tests); `game_wrapper_test.dart` |
| 14 | Explain the score to the user | Done (addition) | `widgets/score_breakdown_sheet.dart` | `score_and_mood_test.dart`: "the breakdown explains the score and the missing signal" |

## 5.3 Daily quests

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 15 | Box Breathing, 2 min, +40 XP | Done | `widgets/quick_breathing_card.dart`. It completes only after all four rounds. | `quests_screen_test.dart`: "the Box Breathing quest opens a breathing session and completes…"; `quick_breathing_card_test.dart`: "stopping early never completes" |
| 16 | Screen Sabbath +60, Micro Walk +50, Hydration +20, Posture +25 | Done | `mock_data.dart` quest list, `screens/quests/quests_screen.dart`. These are honour-system: the app can't verify a walk. | `app_state_test.dart`: "completing a quest awards its XP once and survives a restart" |
| 17 | Quests surfaced contextually | Partial | Home suggests a game from today's stress, mood and focus (`services/game_recommender.dart`). The quest list itself is fixed. | `game_recommender_test.dart` (4 tests) |
| 18 | XP and levels | Done | `services/progress_engine.dart`: 250 XP per level, all XP from stored events | `progress_engine_test.dart`: "every 250 XP is one level, starting at level 1"; `app_state_test.dart`: "a fresh install has no fake progress" |

## 5.4 Insights dashboard

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 19 | 7-day trend of CogniPulse, stress and mood | Done | `screens/insights/insights_screen.dart`, `CogniPulseEngine.lastDays` | `insights_screen_test.dart`: "a week of check-ins shows real weekdays, patterns and history"; `cognipulse_engine_test.dart`: "returns 7 days oldest first ending today, with gaps as null" |
| 20 | Plain-language pattern insights (triggers, peak windows) | Changed | `services/insight_engine.dart`. Rule-based, not AI-generated: trend, best day, morning vs evening, typing vs mood, consistency. | `insight_engine_test.dart` (9 tests) |
| 21 | Empty states when there's no data | Done (addition) | `insights_screen.dart` | `insights_screen_test.dart`: "a fresh install shows empty states instead of fake numbers" |

## 5.5 Avatars and skins

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 22 | Choose from 5 creatures at onboarding, Mochi default | Changed | `screens/onboarding/onboarding_pages.dart` (`AvatarSelectionPage`). Five are shown, but the names and unlocks differ from the PRD: | `app_smoke_test.dart` (goes through onboarding) |
| | | | PRD: Mochi, Nyx (Level 5), Flux (Level 10), Pip (30-day streak), Lumi (CogniPulse 90+) | |
| | | | App: Mochi, Luna (Level 5), Kai (7-day streak), Nova (30-day streak), Zara (Level 10) | |
| 23 | Unlockable skins | Not built | The other four creatures are always shown as locked; there's no unlock logic or artwork for them. Badges do unlock from real progress. | `progress_engine_test.dart`: "badges unlock from real stats and report progress" |

## 6. Key user flows

| # | Requirement | Status | Code | Test |
|---|---|---|---|---|
| 24 | Onboarding: name, avatar, 5-question baseline, Meet Mochi, home | Done | `screens/onboarding/onboarding_flow.dart`, `baseline_page.dart` | `app_smoke_test.dart`: "onboarding baseline answers become the starting score"; `baseline_page_test.dart` (2 tests) |
| 25 | Onboarding: keyboard-layer permission | Not built | There's no keyboard layer (row 10). The permissions page lists what is used instead. | |
| 26 | Onboarding: notification permission | Not built | The app sends no notifications. | |
| 27 | Daily loop: tap to check in, score updates, quest suggestions | Done | Home | `score_and_mood_test.dart`; `home_daily_quest_test.dart`: "Daily Quest on Home opens the Quests tab" |
| 28 | Daily loop: morning "vibe check" notification | Not built | No notifications. Mochi's greeting changes with time of day instead. | |
| 29 | Daily loop: streaks | Done | `ProgressEngine.currentStreak` | `progress_engine_test.dart`: "a streak ending yesterday is still alive today", "streaks survive the month boundary" |
| 30 | Stress detection: passive background collection every 2 h | Partial | Signals are active check-ins, not background collection. The score is recomputed on every check-in, on resume and at midnight. | `day_rollover_watcher_test.dart`: "an app left open past midnight starts the new day" |
| 31 | Stress detection: Mochi changes state, relevant activity surfaced | Done | `mochiMoodProvider`, `GameRecommender` (calming Wave Sync when stress is high) | `game_recommender_test.dart`: "high stress or a low score suggests calming Wave Sync" |

## 7. Non-functional requirements

| # | Requirement | Status | Notes | Test |
|---|---|---|---|---|
| 32 | Privacy: all inference on-device | Done | ML Kit runs on-device. Nothing is uploaded. The only network call is the optional Ollama request on the local network. | `ollama_service_test.dart`: "dialogue falls back to built-in lines when the host is unreachable" |
| 33 | Launch < 2 s, CogniPulse update < 500 ms | Partial | Not measured with a profiler. The score is a pure in-memory calculation over at most 60 days of readings. | |
| 34 | Background tracking < 3% battery | Not built | There's no background tracking, so nothing to measure. Counted as not built because the feature it limits isn't built. | |
| 35 | Accessibility: WCAG 2.1 AA, screen reader | Partial | Mood buttons have semantic labels. No audit has been done. | |
| 36 | Offline: Mochi and quests work without internet | Done | Ollama falls back to built-in dialogue. Fonts come from Google Fonts, so a phone that has never been online shows the system font. | `ollama_service_test.dart`: "ping is MOCK on a server error or no connection" |
| 37 | Data stored locally | Done | `services/wellness_repository.dart`, `face_scan_repository.dart`, `game_repository.dart`. There's no cloud sync. | `wellness_repository_test.dart` (5 tests); `game_repository_test.dart` (7 tests) |
| 38 | Corrupt data never crashes the app | Done (addition) | Repositories load bad JSON as empty. | `wellness_repository_test.dart`: "corrupt JSON loads as empty instead of crashing"; `app_state_test.dart`: "corrupt face scan history starts the app with no scans" |

## 9. Risks and mitigations

| # | Mitigation in the PRD | Status | Code | Test |
|---|---|---|---|---|
| 39 | Transparency at onboarding, wellness-not-diagnostic disclaimer | Partial | The permissions page says everything stays on the phone and marks phone usage "coming later"; the About sheet and score breakdown say ZENO isn't a medical tool. The "30-day behavioural model" mitigation isn't built (row 3). | `profile_settings_test.dart`: "About says what is and is not measured" |

## 8. Out of scope for the MVP

Therapist integration, smartwatch integration, social feed, a web version and billing are all out of scope in the PRD, and none were built. Flutter generated `web/`, `linux/`, `macos/` and `windows/` folders, but only Android is supported and tested.

## 3.2 Success metrics

Retention, daily usage, CogniPulse agreement and quest-completion rates need real users over weeks. A demo build can't measure them, so they aren't tracked here.
