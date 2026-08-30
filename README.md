# Ahmed OS — v1

Daily focus, goals, training log. Four tabs, one loop, nothing else.

## Run it

Requires **Flutter 3.27 or newer** (`flutter --version`).

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

> This code was written without a Flutter toolchain available, so it has not
> been compiled. `flutter analyze` is the first thing to run — if anything is
> off, it will be a missing import or a signature nit, not a design problem.

## Where the data lives

Everything is one JSON document on the device, written through
`shared_preferences` (`lib/data/local_store.dart`). That is a deliberate v1
choice, not a shortcut:

- The same build runs on Chrome, Windows, Android and iOS with nothing to
  install — no native database plugin, no `sqlite3.wasm`, no platform config.
- Volumes here are hundreds of records, so in-memory filtering is faster than
  a query planner would be.
- The schema is exactly the one in the design handoff. Moving to SQLite or
  Supabase later means replacing that one file; the models, logic and UI
  above it do not change.

Profile → Export everything copies the whole document as JSON. Profile →
Erase everything wipes it.

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

Accounts, cloud sync, push notifications, XP, levels, badges, a web build
you would have to maintain, and any external integration. The next honest
step is Supabase sync behind `LocalStore` — once the app has earned it by
being opened every day for a few weeks.
