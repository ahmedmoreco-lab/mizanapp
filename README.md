# Ahmed OS — v1

Daily focus, goals, training log. Four tabs, one loop, nothing else.

## Run it

The deployed web app is available at:

https://mizan-app-7fa3f.web.app

For local development, use **Flutter 3.27 or newer** (`flutter --version`):

```bash
flutter pub get
flutter run -d chrome        # fastest way to see it — no extra toolchain
```

`web/` ships with the project, so Chrome works out of the box. For the other
targets, generate their platform folders first (this only adds directories —
it does not touch `lib/`):

```bash
flutter create --platforms=windows,android .
flutter run -d windows       # needs Visual Studio with the C++ desktop workload
flutter run -d <device-id>   # Android phone over USB; flutter devices to list
```

Checks, in the order worth running them:

```bash
dart format .
flutter analyze
flutter test
```

## Where the data lives

Each email/password account owns one JSON document in Cloud Firestore. The
document is also cached with `shared_preferences`, under a key namespaced by
Firebase user ID, so accounts cannot read each other's device cache.

- Local writes happen first, so temporary connection loss does not discard an
  edit. Pending changes are sent when Firestore reconnects.
- Firestore security rules only allow an authenticated user to read or write
  `users/{their-user-id}/state/app`.
- The first account used on an upgraded device claims the old device-only
  document once, then the legacy copy is removed.

Profile → Export everything copies the whole document as JSON. Profile →
Erase everything replaces the synced document with a blank one on every
device.

## Layout

```
lib/
  models/     pillars, goals, tasks, exercises, workouts, sets, settings
  data/       the JSON document and how it is read and written
  logic/      focus engine, streaks, goal progress, chart series
  state/      AppState — every read and every mutation, one place
  theme/      the design tokens, and the two ThemeData built from them
  ui/         shell + four tabs + the sheets they open
test/         the logic, covered
```

`lib/theme/tokens.dart` is the source of truth for every colour, size and
weight in the app. Nothing else hard-codes a value, which is why light and
dark cannot drift apart.

## The decisions worth knowing

**Home suggests, you confirm.** First open of the day is the suggestion
screen with one Confirm button; after that Home is just today. Each
suggestion states the rule that surfaced it — "Untouched for 6 days —
longest gap", "2 tasks overdue" — because a ranking you can read is a
ranking you can overrule. Weights live in `FocusEngine`.

**Three pillars sit out of the suggestions.** Personal, Content and Rest are
aspirational, so they stay taggable but are switched out of the neglect
algorithm (Profile → Pillars). Otherwise every morning would open with three
pillars reporting a forty-day gap, and you would stop reading the screen.
Flip them on the day one becomes real.

**Workout → exercises → sets, editable at every level.** Swipe a set to
delete it, tap it to edit. The ⋮ handles exercises and whole workouts.
Each exercise header carries "Last time · 90 kg × 5", so you pick today's
load with last week's in front of you.

**Templates are workouts with no date.** `is_template = true`, which is why
"save as template" costs nothing. Starting from one copies the exercise list
and leaves the numbers empty.

**Running is flat.** A run is distance, time, RPE, notes, with pace computed
for you. Same tables underneath — one set on one "Run" exercise — but the
screen does not make you build a list for a single activity.

**Deleting an exercise from the library is blocked, not cascaded.** If "Back
squat" has history, deleting it would erase the chart it took months to
build; the app offers rename or archive. Deleting one workout does cascade —
that one is unambiguous.

**Disabled is a real state.** Finish workout stays disabled until a set
exists; Save set until a number does; Create goal until there is a title.
There is never a validation error to show.

## Not in v1, on purpose

Push notifications, XP, levels, badges, and external integrations remain out
of scope. Accounts and cloud sync use Firebase Authentication and Firestore;
the web build is published with Firebase Hosting.
