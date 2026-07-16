# Mizan migration audit

Audit date: 2026-07-16  
Migration branch: `feature/mizan-mvp`

## Baseline

- Flutter 3.29.3 / Dart 3.7.2; package name remains `soulping_care`.
- `flutter analyze` passed before migration.
- The original widget test failed before migration because it pumped `MyApp`
  without the required `LocaleProvider`.
- The original app built and launched in Chrome and initialized the existing
  Firebase project. Windows launch was blocked by a missing Visual Studio
  desktop toolchain.
- `lib/main.dart` already contained an uncommitted Firebase channel-error retry
  workaround. It is preserved in
  `lib/legacy/soulping_firebase_bootstrap.dart` and is not called by Mizan.
- `build_log.txt` was already untracked and has not been modified.

## Current architecture

- Entry point: `lib/main.dart`.
- State management: Provider / ChangeNotifier.
- Localization: hand-written `AppLocalizations`, Material/Cupertino delegates,
  persisted `LocaleProvider`, English and Arabic, with Flutter-provided RTL.
- Theme: Material 3 in `lib/utils/theme.dart`.
- Legacy navigation: named routes plus direct `Navigator` calls in old auth and
  role screens. Mizan uses a five-destination `NavigationBar` and a direct route
  to Work Mode.
- Existing backend: Firebase Auth, Firestore, FCM, Cloud Functions, local
  notifications, Workmanager, and an Android foreground service.
- Active Mizan backend: Firebase Core initializes the new Mizan project on web
  and desktop, but no Firebase product reads or writes data. Planning remains
  local mock data; SharedPreferences stores only the language selection.

## Reuse as-is

- Flutter platform projects, build configuration, dependency setup, and asset
  loading.
- `provider` and the existing ChangeNotifier approach.
- Flutter localization delegates, `LocaleProvider`, EN/AR locale selection, and
  RTL behavior.
- General Material navigation patterns and platform-responsive widgets.
- Existing Firebase platform files are retained untouched as legacy reference.
  Android/iOS do not initialize them from the Mizan bootstrap.

## Reuse after modification

- `lib/utils/theme.dart`: now provides the Mizan Material 3 palette and component
  defaults.
- `lib/l10n/app_localizations.dart`: app title updated; new Mizan copy is kept in
  a focused localization extension.
- Firebase Auth screens/services/providers could later be adapted to the new
  Mizan project and user schema.
- Local notification infrastructure could later support wake, routine, focus,
  and reflection reminders after the safety-specific channels and payloads are
  separated.
- `CustomButton` and `CustomTextField` are potentially reusable after their old
  visual assumptions and import paths are reviewed.

## SoulPing-specific and eventually remove

- Models: `lib/models/checkin_model.dart` and the elder/contact fields in
  `lib/models/user_model.dart`.
- Providers: `elder_provider.dart`, `contact_provider.dart`, and
  `monitoring_provider.dart`.
- Services: `background_check_service.dart`, `monitoring_service.dart`,
  `foreground_task_handler.dart`, and most safety/check-in operations in
  `firestore_service.dart` and `local_notification_service.dart`.
- UI: elder dashboard, trusted-contact dashboard, contact setup, SOS states,
  safety monitoring toggle, premium safety paywall, and role selection.
- Backend: `functions/index.js`, the current Firestore rules/data layout, SOS
  triggers, missed-check-in escalation, and inactivity checks.
- Android safety permissions, foreground-service declaration, boot receiver,
  exact-alarm declarations, and old internal channel/task identifiers.
- Legacy safety localization keys and the existing safety-oriented app icon and
  splash assets.

These items are isolated from the active Mizan bootstrap but intentionally have
not been deleted.

## Unclear or risky

- The new Android Firebase registration targets `com.mizzan.mizzanapp`, while
  this copy is still `com.example.flutter_application_1`. The supplied JSON was
  not installed because Gradle would reject the package mismatch.
- The new iOS Firebase registration targets `con.mizan.mizanapp` (possibly a
  `con`/`com` typo), while this copy is still
  `com.example.flutterApplication1`. The supplied plist was not installed.
- The current `firebase.json`, old generated options, old Google service files,
  signing, package IDs, and bundle IDs remain legacy configuration. In
  particular, deploying the legacy Cloud Functions to the new project would be
  unsafe.
- The Android manifest still registers legacy safety services and permissions.
  They are dormant from Dart startup but should be removed only after checking
  plugin requirements and previously scheduled work on upgrade installs.
- The old Firestore `users` schema is role-based (`elder` / `contact`) and does
  not represent `UserProfile`, plans, tasks, routines, meals, or reflections.
- Authentication is retained but not reachable from the Mizan MVP. Re-enabling
  it before configuring the new Firebase app would create an accidental legacy
  dependency.
- Mock plan and progress state is memory-only and resets when the process exits.
  Only language choice is currently persisted.
- Profile goals are mock English content. Core navigation and planning content
  has Arabic presentation support, but user-entered/profile data will require a
  product decision rather than automatic translation.
- Windows desktop verification requires a Visual Studio C++ Flutter toolchain.

## Missing for the Mizan MVP roadmap

- Persistent local repository for daily plans, task state, wake-up answers, and
  reflections.
- Onboarding/profile editing and a real first-run flow.
- Matching mobile registrations/package identities, authentication integration,
  security rules, repositories, and migration strategy for the new Mizan
  Firebase project.
- Safe notification scheduling for wake-up, work blocks, breaks, meals, and
  reflection.
- Real calendar/time-zone scheduling, recurrence, and day rollover.
- Accessible empty/error states, deeper Arabic copy review, and device testing.
- AI recommendations are intentionally absent.

## MVP implemented in this branch

- Local-only Mizan application shell and visible platform branding.
- Today, Tasks, Meals, Reflection, and Profile navigation.
- Typed Mizan models and deterministic mock daily-plan generation.
- Wake-up check-in that refreshes workday, training, and energy assumptions.
- Single-task Work Mode with Start, Pause, Complete, and Skip behavior.
- Local in-memory routine/task/reflection progress and EN/AR presentation.
