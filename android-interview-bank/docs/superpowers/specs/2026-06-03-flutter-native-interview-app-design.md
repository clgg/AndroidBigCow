# Flutter Native Interview App Design

## Goal

Build a Flutter native offline Android interview question app from the existing Markdown bank. The app should feel like the supplied mobile reference: compact cards, high whitespace discipline, rounded controls, strong accent color, and four switchable styles: blue, purple, orange, and dark.

## Scope

The MVP includes module browsing, question browsing, search, tag filtering, question details, random question entry, favorites, and review status: not mastered, mastered, and next review. It also includes a settings screen for theme switching and progress reset/export display.

The MVP excludes account login, cloud sync, online updates, and WebView rendering.

## Architecture

Use a single Flutter app with small domain models, an in-memory repository seeded from bundled asset data, and local persistence for user state. Content data and user progress stay separate so question bank updates do not erase review state.

## Screens

- Home: module summary cards, progress counters, today's review entry, random question action.
- Bank: searchable and filterable list of questions by module and tag.
- Question Detail: question, answer points, follow-up questions, common mistakes, favorite toggle, and review-state actions.
- Review: saved subsets for next review, not mastered, favorites, and random practice.
- Settings: visual style switcher, progress export preview, and reset action.

## Data

Each question has id, module, title, tags, reviewStatus seed, checkpoints, answer points, follow-up prompts, and common mistakes. User state stores favorite flag and review status by question id.

## Visual Direction

Use the reference only for style, not exact features. The UI should use phone-native card surfaces, small caption labels, pill filters, low-shadow borders, and clear accent actions. Theme switching changes accent, surface tint, text contrast, selected-pill styling, and bottom navigation state.

## Testing

Add widget/model tests for repository filtering, state persistence serialization, and main navigation smoke coverage. Run `flutter test` and `flutter analyze` before handoff.
