# Thryve — intentional progress, made simple

Thryve is a local-first personal growth app for turning a meaningful dream into
small daily actions. It supports personal (milestone) and financial goals, daily
practices with a real streak, a visual Wall, weekly reflection, daily reminders,
and light/dark appearance. Everything stays on the device.

## Run

```bash
flutter pub get
flutter run
```

Requires Dart 3.12+ (Flutter stable). Checks:

```bash
flutter analyze   # flutter_lints + strict set in analysis_options.yaml
flutter test
dart format --output=none --set-exit-if-changed lib test
```

CI (`.github/workflows/ci.yml`) runs the same three checks plus a debug
Android build on every push and pull request.

## Release

Thryve is built by Bling. The application ID is `com.bling.thryve` on every
platform.

- **Android signing:** create `android/key.properties` (git-ignored) with
  `storeFile`, `storePassword`, `keyAlias` and `keyPassword`. With it,
  `flutter build appbundle` signs with your release key; without it the build
  falls back to the debug key so local `--release` runs still work.
- **Permissions:** Android declares `INTERNET` (remote Wall images) and
  `POST_NOTIFICATIONS` (daily reminder). iOS asks for photo-library and
  notification access. macOS has network-client and file-selection
  entitlements.
- **Backups:** Android cloud backup is disabled because all data is personal
  and device-local.

## Architecture

**Feature-first MVVM with Provider.** `AppStore` owns loading and saving.
Each feature has its own view model that sits next to its screen
(`home_screen.dart` + `home_view_model.dart`), reads the slices of state it
needs from the store, and writes back through it. A view model only notifies
when one of its slices changes, so a Wall edit doesn't rebuild Goals.

View models extend `ViewModel` (or `StoreViewModel` for store-backed features).
Create them with `ChangeNotifierProvider(create: ...)` so Provider owns their
disposal. Shared feature models live in `app.dart`; screen and sheet models
live at their UI boundary. Render reactive content with `Consumer<T>` (or
`Consumer2` for two dependencies), and use `context.read<T>()` in action handlers
to access a model without subscribing to changes. Form controllers belong to
the view model and are disposed with it.

```
lib/
├── main.dart                 # bootstrap: notifications + image storage
├── app.dart                  # providers, theme, onboarding/shell gate
├── core/
│   ├── constants/            # storage keys, ids
│   ├── extensions/           # context.colors / context.text / showSnack
│   ├── services/             # NotificationService, ImageStore, ReminderCopy
│   ├── state/                # AppStore (persistence), StoreViewModel, ViewModel
│   ├── theme/                # color schemes (light + dark), ThemeData, ThemeManager
│   ├── utils/                # dates, formatting, streak calculation
│   └── widgets/              # cards, buttons, sheets, page scaffolds, images
├── data/
│   ├── models/               # immutable models with JSON (+ v1 migration)
│   └── repositories/         # AppStateRepository (SharedPreferences)
└── features/
    ├── onboarding/           # 3 steps: name & dream → anchor → reminder time
    ├── shell/                # bottom navigation
    ├── home/                 # focus goal, today's practices, Wall reminder
    ├── goals/                # hub, detail, achievement, goal & milestone sheets
    ├── wall/                 # inspiration Wall and editor
    ├── review/               # weekly check-in + history
    ├── settings/             # profile, appearance, reminders, reset, about, privacy policy
    └── support/              # optional tip QR
```

| Layer | Responsibility |
|-------|----------------|
| `AppStore` | Load/save, save-failure flag, day rollover, activity, image bookkeeping |
| `GoalsViewModel` | Goals, milestones, earnings, level-up |
| `HomeViewModel` | Daily practices, streak, featured Wall item |
| `WallViewModel` | Wall items and pinning |
| `SettingsViewModel` | Profile, reminders, reset |
| `WeeklyReviewViewModel` | Week summary, past reviews, check-in form |
| `OnboardingViewModel` | Onboarding steps; creates the profile and first goal |
| `AppStateRepository` | One JSON document in SharedPreferences; serialized writes; corrupt data is backed up, never crashes |
| `OnboardingViewModel` | Step navigation, validation, anchor image, reminder time |
| `WeeklyReviewViewModel` | This week's rating and reflection form |
| `MainShellViewModel` | Selected tab (`context.goToTab(...)`) |

### Rules worth knowing

- **Achievement** — a goal completes when all its milestones are completed
  or a money goal reaches its target. It can also be marked complete by hand,
  or reopened.
- **Focus goal** — Home shows the first active goal. Use *Make focus goal* on
  any goal to move it there.
- **Streak** — counts consecutive days with at least one action (practice
  checked, milestone completed, earnings logged). Today counts once you act,
  and yesterday's streak holds until then.
- **Daily practices** — checkmarks reset when the day changes, including when
  the app comes back to the foreground.
- **Weekly review** — one entry per Monday–Sunday week. Past weeks are kept.
- **Images** — picked photos are copied to the app documents folder and
  stored as `local:<file>` references (portable across iOS container moves).
  Replaced and removed images are deleted. Older base64 entries still render.
- **Reminders** — scheduled in the device's timezone. The notification text
  is the same `ReminderCopy` shown in the onboarding preview.

## Design system

Emerald Clarity (light) / Emerald Nocturne (dark), built from full Material 3
`ColorScheme`s in `core/theme/app_colors.dart`. Widgets read colors through
`context.colors`, never constants, so every screen follows the selected
theme. Typeface: **Geist**, bundled in `assets/fonts` (no runtime download).

## Data compatibility

State saved by the earlier build (schema v1) loads unchanged. The migration
covers the string focus time, flag-only achievement, the single weekly review,
and the `imageUrl`/`avatarUrl` keys. See `test/data/app_state_migration_test.dart`.
