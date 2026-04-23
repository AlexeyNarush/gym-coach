# Gym Coach (MVP)

Gym Coach is a beginner-friendly Flutter workout app focused on consistency:

- structured 3-day split planning
- adaptive daily workout generation
- in-workout completion + per-set logging
- local workout history for progression

This MVP is Android-first and iOS-ready.

## MVP Features

### Plan tab
- Shows the configured weekly training days.
- Maps each day to a template (Day A / B / C split).
- Lets users inspect planned exercises.
- Includes **Start this in Today** to preload tracking flow in the Today tab.

### Today tab
- Three generation modes:
  - **Use my history** (history-adapted session)
  - **Select muscle group** (targeted session)
  - **Use planned template** (direct template session)
- Per-exercise planned targets:
  - sets x reps for rep-based work
  - sets x seconds for timed work
- Real-time completion tracking:
  - exercise completion progress bar
  - per-exercise set progress
- Per-set logging:
  - reps, duration, optional weight (kg)
  - set logs persist unless explicitly cleared
- Exercise alternatives and swap flow.
- Session save with difficulty + notes to local history.

### Exercise library
- Seeded exercise catalog with:
  - muscle groups
  - difficulty
  - equipment type
  - alternatives (equipment/joint-friendly)
- Simple movement-pattern illustrations in `assets/exercises/patterns/`.

### App/UI
- Dark mode enabled for the app theme.
- Riverpod state management + GoRouter navigation.

## Tech Stack

- Flutter + Dart
- `flutter_riverpod`
- `go_router`
- `shared_preferences`
- `flutter_svg`

## Getting Started

### Prerequisites
- Flutter SDK installed and available on PATH
- Android SDK (for Android runs)
- JDK 17 (required by current Android Gradle setup)

### Run

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart
```

## Project Structure

- `lib/app/` - app shell, router, theme
- `lib/features/` - plans, today, exercises, history, settings
- `lib/core/` - local persistence + provider wiring + sync/notification abstractions
- `assets/exercises/patterns/` - reusable SVG movement-pattern illustrations
- `docs/EXERCISE_PROGRAM_PLAN.md` - exercise programming guide aligned with seed templates

## Data and Persistence (MVP)

- History is stored locally via `shared_preferences` through `AppDatabase`.
- Sync is currently a no-op implementation (`NoOpSyncRepository`) designed for future cloud integration.

## Post-MVP Hooks

- Reminder scheduling through `ReminderPreferences` + `NotificationService`.
- Cloud sync implementation via `SyncRepository`.
