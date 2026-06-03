# Flutter Native Interview App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Flutter MVP for offline Android interview question practice.

**Architecture:** Create a Flutter app in the repository root, seed structured question data from the existing Markdown files, and keep mutable review/favorite/theme state in local storage. UI uses compact native Flutter widgets and a small theme system inspired by the provided reference.

**Tech Stack:** Flutter 3.41, Dart 3.11, `shared_preferences`, `flutter_lints`, Flutter widget tests.

---

### Task 1: Scaffold Flutter App

**Files:**
- Create: Flutter project files in repository root.
- Modify: `pubspec.yaml`

- [ ] Create the Flutter project with `flutter create --project-name android_interview_bank --platforms android,windows .`.
- [ ] Add `shared_preferences` to runtime dependencies.
- [ ] Add bundled assets path `assets/question_bank.json`.
- [ ] Run `flutter pub get`.

### Task 2: Add Data Model And Repository

**Files:**
- Create: `lib/models/question.dart`
- Create: `lib/models/user_progress.dart`
- Create: `lib/data/question_repository.dart`
- Create: `assets/question_bank.json`
- Test: `test/question_repository_test.dart`

- [ ] Write failing repository tests for module grouping, search, tag filtering, and status overlay.
- [ ] Implement immutable question and progress models.
- [ ] Implement repository methods for all questions, modules, tags, search/filter, random selection, and status subsets.
- [ ] Run the repository test and verify it passes.

### Task 3: Add Local App State

**Files:**
- Create: `lib/state/app_controller.dart`
- Test: `test/user_progress_test.dart`

- [ ] Write failing tests for progress JSON serialization and review-state updates.
- [ ] Implement `AppController` with loading, favorite toggle, status update, theme update, reset, and local persistence.
- [ ] Run the state tests and verify they pass.

### Task 4: Build Native UI

**Files:**
- Replace: `lib/main.dart`
- Create: `lib/theme/app_theme.dart`
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/bank_screen.dart`
- Create: `lib/screens/question_detail_screen.dart`
- Create: `lib/screens/review_screen.dart`
- Create: `lib/screens/settings_screen.dart`
- Create: `lib/widgets/app_shell.dart`
- Create: `lib/widgets/question_card.dart`

- [ ] Implement theme tokens for blue, purple, orange, and dark styles.
- [ ] Implement tab shell with Home, Bank, Review, and Settings.
- [ ] Implement searchable/filterable question bank and detail navigation.
- [ ] Implement review actions, favorite toggle, random practice, and settings theme switcher.

### Task 5: Verify

**Files:**
- Modify: `test/widget_test.dart`

- [ ] Update widget smoke test to load the app and verify the main tabs render.
- [ ] Run `dart format .`.
- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
