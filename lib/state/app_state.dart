import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../data/notion_import.dart';
import '../data/training_plan.dart';
import '../logic/focus_engine.dart';
import '../logic/progress.dart';
import '../logic/streaks.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/goal.dart';
import '../models/pillar.dart';
import '../models/set_entry.dart';
import '../models/task.dart';
import '../models/workout.dart';

const _uuid = Uuid();

/// Raised when an operation would silently destroy history.
class BlockedOperation implements Exception {
  BlockedOperation(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  AppState({DocumentStore? store}) : _store = store ?? LocalStore() {
    _store.syncStatus.addListener(_notifySyncStatusChanged);
    _store.syncMessage.addListener(_notifySyncStatusChanged);
  }

  final DocumentStore _store;
  StreamSubscription<Map<String, Object?>>? _storeSubscription;

  bool _ready = false;
  bool get isReady => _ready;
  String? get accountEmail => _store.accountEmail;
  bool get isCloudBacked => _store.isCloudBacked;
  SyncStatus get syncStatus => _store.syncStatus.value;

  /// Set only when the server refused a write — never for a dropped
  /// connection, which clears itself.
  String? get syncMessage => _store.syncMessage.value;

  final List<Task> _tasks = [];
  final List<Goal> _goals = [];
  final List<Workout> _workouts = [];
  final List<Exercise> _exercises = [];

  AppSettings _settings = AppSettings();
  bool _notionImported = false;
  bool _trainingPlanImported = false;

  bool get hasImportedNotion => _notionImported;
  bool get hasImportedTrainingPlan => _trainingPlanImported;

  // ---------------------------------------------------------------- read

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Exercise> get exercises => List.unmodifiable(_exercises);
  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;

  List<Workout> get workouts =>
      _workouts.where((w) => !w.isTemplate).toList(growable: false);

  List<Workout> get templates =>
      _workouts.where((w) => w.isTemplate).toList(growable: false);

  List<Workout> workoutsOfType(WorkoutType type) {
    final list = _workouts
        .where((w) => !w.isTemplate && w.type == type)
        .toList()
      ..sort(
          (a, b) => (b.date ?? b.createdAt).compareTo(a.date ?? a.createdAt));
    return list;
  }

  List<Workout> templatesOfType(WorkoutType type) =>
      _workouts.where((w) => w.isTemplate && w.type == type).toList();

  List<Exercise> exercisesOfType(WorkoutType type) {
    final list =
        _exercises.where((e) => !e.isArchived && e.type == type).toList()
          ..sort((a, b) {
            final al = a.lastUsedAt;
            final bl = b.lastUsedAt;
            if (al == null && bl == null) return a.name.compareTo(b.name);
            if (al == null) return 1;
            if (bl == null) return -1;
            return bl.compareTo(al);
          });
    return list;
  }

  Exercise? exerciseById(String? id) {
    if (id == null) return null;
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  String exerciseName(String id) => exerciseById(id)?.name ?? 'Exercise';

  Workout? workoutById(String id) {
    for (final w in _workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  Goal? goalById(String id) {
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<Task> tasksForGoal(String goalId) {
    final list = _tasks.where((t) => t.goalId == goalId).toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return _taskOrder(a, b);
      });
    return list;
  }

  GoalProgress progressForGoal(String goalId) => goalProgress(goalId, _tasks);

  TrainingStats get trainingStats => computeTrainingStats(_workouts);

  int get completedGoals =>
      _goals.where((g) => g.status == GoalStatus.done).length;


  // -------------------------------------------------------------- agenda

  /// Worst pillar gaps first — the one line Home shows in place of the
  /// pillar cards.
  List<PillarNeglect> get pillarGaps => pillarNeglect(
        eligible: _settings.suggestingPillars,
        tasks: _tasks,
        workouts: _workouts,
      );

  /// Due today, plus anything already overdue. An overdue task must never
  /// quietly fall off the only screen you open every day.
  List<Task> get todayTasks {
    final list = _tasks
        .where((t) => !t.done && (t.isDueToday || t.isOverdue))
        .toList()
      ..sort(_taskOrder);
    return list;
  }

  /// Finished today, so the day shows what it earned rather than only
  /// what is left.
  List<Task> get doneToday {
    final now = DateTime.now();
    final list = _tasks.where((t) {
      final at = t.completedAt;
      return t.done &&
          at != null &&
          at.year == now.year &&
          at.month == now.month &&
          at.day == now.day;
    }).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return list;
  }

  /// Captured with no date — the loose pile. Newest first, because the
  /// thing you wrote down last is the thing you still remember.
  List<Task> get looseTasks {
    final list = _tasks
        .where((t) => !t.done && t.dueDate == null)
        .toList()
      ..sort(_taskOrder);
    return list;
  }

  /// Everything dated to one day, done included, for the calendar.
  List<Task> tasksOn(DateTime day) {
    final list = _tasks.where((t) {
      final due = t.dueDate;
      return due != null &&
          due.year == day.year &&
          due.month == day.month &&
          due.day == day.day;
    }).toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return _taskOrder(a, b);
      });
    return list;
  }

  /// How many open tasks a day carries — the dot under a date.
  int openCountOn(DateTime day) =>
      tasksOn(day).where((t) => !t.done).length;

  // --------------------------------------------------------------- tasks

  Future<Task> addTask({
    required String title,
    Pillar? pillar,
    String? goalId,
    DateTime? dueDate,
    String notes = '',
    bool isTodayFocus = false,
    Priority? priority,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      pillar: pillar,
      goalId: goalId,
      dueDate: dueDate,
      notes: notes,
      isTodayFocus: isTodayFocus,
      priority: priority,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    await _persist();
    return task;
  }

  Future<void> toggleTask(String id) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = _tasks[i];
    final nowDone = !t.done;
    _tasks[i] = t.copyWith(
      done: nowDone,
      completedAt: nowDone ? DateTime.now() : null,
      clearCompletedAt: !nowDone,
    );
    await _persist();
  }

  Future<void> updateTask(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return;
    _tasks[i] = task;
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _persist();
  }

  // --------------------------------------------------------------- goals

  Future<Goal> addGoal({
    required String title,
    required Pillar pillar,
    String whyItMatters = '',
    String measure = '',
    DateTime? targetDate,
  }) async {
    final goal = Goal(
      id: _uuid.v4(),
      title: title.trim(),
      pillar: pillar,
      status: GoalStatus.notStarted,
      whyItMatters: whyItMatters,
      measure: measure,
      targetDate: targetDate,
      createdAt: DateTime.now(),
      statusChangedAt: DateTime.now(),
    );
    _goals.add(goal);
    await _persist();
    return goal;
  }

  Future<void> updateGoal(Goal goal) async {
    final i = _goals.indexWhere((g) => g.id == goal.id);
    if (i < 0) return;
    final previous = _goals[i];
    _goals[i] = goal.status != previous.status
        ? goal.copyWith(statusChangedAt: DateTime.now())
        : goal;
    await _persist();
  }

  /// Deleting a goal unlinks its tasks rather than deleting them — the
  /// work was still real even if the goal was abandoned.
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].goalId == id) {
        _tasks[i] = _tasks[i].copyWith(clearGoal: true);
      }
    }
    await _persist();
  }

  // ----------------------------------------------------------- exercises

  Future<Exercise> ensureExercise(String name, WorkoutType type) async {
    final trimmed = name.trim();
    final existing = _exercises.where(
      (e) => e.name.toLowerCase() == trimmed.toLowerCase() && e.type == type,
    );
    if (existing.isNotEmpty) return existing.first;

    final created = Exercise(id: _uuid.v4(), name: trimmed, type: type);
    _exercises.add(created);
    await _persist();
    return created;
  }

  Future<void> renameExercise(String id, String name) async {
    final i = _exercises.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _exercises[i] = _exercises[i].copyWith(name: name.trim());
    await _persist();
  }

  bool exerciseHasHistory(String id) => _workouts
      .any((w) => !w.isTemplate && w.exercises.any((e) => e.exerciseId == id));

  /// Blocked while history references it. Deleting "Back squat" with eight
  /// workouts behind it would erase the chart it took months to build.
  Future<void> deleteExercise(String id) async {
    if (exerciseHasHistory(id)) {
      throw BlockedOperation(
        '${exerciseName(id)} has logged sets. Archive or rename it instead.',
      );
    }
    _exercises.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> archiveExercise(String id, {bool archived = true}) async {
    final i = _exercises.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _exercises[i] = _exercises[i].copyWith(isArchived: archived);
    await _persist();
  }

  /// The lift plotted in the chart for its type. One per type.
  Future<void> setTrackedExercise(String id) async {
    final target = exerciseById(id);
    if (target == null) return;
    for (var i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      if (e.type != target.type) continue;
      _exercises[i] = e.copyWith(isTracked: e.id == id);
    }
    await _persist();
  }

  Exercise? trackedExercise(WorkoutType type) {
    for (final e in _exercises) {
      if (e.type == type && e.isTracked && !e.isArchived) return e;
    }
    final ofType = exercisesOfType(type);
    return ofType.isEmpty ? null : ofType.first;
  }

  ChartSeries seriesFor(WorkoutType type) {
    final tracked = trackedExercise(type);
    return buildSeries(
      workouts: _workouts,
      type: type,
      exerciseId: type.chartsByExercise ? tracked?.id : null,
    );
  }

  /// "Last time · 90 kg × 5" for the exercise header.
  String? lastPerformance(String exerciseId, {String? excludingWorkoutId}) {
    final sessions = _workouts
        .where((w) =>
            !w.isTemplate &&
            w.id != excludingWorkoutId &&
            w.date != null &&
            w.exercises.any((e) => e.exerciseId == exerciseId))
        .toList()
      ..sort((a, b) => b.date!.compareTo(a.date!));
    if (sessions.isEmpty) return null;

    for (final w in sessions) {
      for (final we in w.exercises) {
        if (we.exerciseId != exerciseId) continue;
        final top = we.topSet ?? (we.sets.isEmpty ? null : we.sets.first);
        if (top != null && !top.isEmpty) return top.summary();
      }
    }
    return null;
  }

  // ------------------------------------------------------------ workouts

  Future<Workout> startBlankWorkout(WorkoutType type) async {
    final workout = Workout(
      id: _uuid.v4(),
      type: type,
      title: _defaultTitle(type),
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _workouts.add(workout);
    await _persist();
    return workout;
  }

  Future<Workout> startFromTemplate(String templateId) async {
    final template = workoutById(templateId);
    if (template == null) {
      throw BlockedOperation('That template no longer exists.');
    }
    final workout = Workout(
      id: _uuid.v4(),
      type: template.type,
      title: template.title,
      date: DateTime.now(),
      templateId: template.id,
      createdAt: DateTime.now(),
      exercises: [
        for (var i = 0; i < template.exercises.length; i++)
          WorkoutExercise(
            id: _uuid.v4(),
            exerciseId: template.exercises[i].exerciseId,
            orderIndex: i,
            // The target — sets, reps, load, cue — travels with the
            // exercise, so it is in front of you while you log.
            notes: template.exercises[i].notes,
          ),
      ],
    );
    _workouts.add(workout);
    await _persist();
    return workout;
  }

  Future<void> saveWorkout(Workout workout) async {
    final i = _workouts.indexWhere((w) => w.id == workout.id);
    if (i < 0) {
      _workouts.add(workout);
    } else {
      _workouts[i] = workout;
    }
    if (!workout.isTemplate) {
      final when = workout.date ?? DateTime.now();
      for (final we in workout.exercises) {
        final ei = _exercises.indexWhere((e) => e.id == we.exerciseId);
        if (ei >= 0) {
          _exercises[ei] = _exercises[ei].copyWith(lastUsedAt: when);
        }
      }
    }
    await _persist();
  }

  Future<void> deleteWorkout(String id) async {
    _workouts.removeWhere((w) => w.id == id);
    await _persist();
  }

  Future<Workout> saveAsTemplate(String workoutId, {String? title}) async {
    final source = workoutById(workoutId);
    if (source == null) {
      throw BlockedOperation('That workout no longer exists.');
    }
    final template = Workout(
      id: _uuid.v4(),
      type: source.type,
      title: (title ?? source.title).trim(),
      isTemplate: true,
      createdAt: DateTime.now(),
      exercises: [
        for (var i = 0; i < source.exercises.length; i++)
          WorkoutExercise(
            id: _uuid.v4(),
            exerciseId: source.exercises[i].exerciseId,
            orderIndex: i,
            notes: source.exercises[i].notes,
          ),
      ],
    );
    _workouts.add(template);
    await _persist();
    return template;
  }

  Future<void> renameTemplate(String id, String title) async {
    final i = _workouts.indexWhere((w) => w.id == id);
    if (i < 0) return;
    _workouts[i] = _workouts[i].copyWith(title: title.trim());
    await _persist();
  }

  // --- exercise + set editing inside a workout -------------------------

  Workout _requireWorkout(String id) {
    final w = workoutById(id);
    if (w == null) throw BlockedOperation('That workout no longer exists.');
    return w;
  }

  Future<void> addExerciseToWorkout(String workoutId, String exerciseId) async {
    final w = _requireWorkout(workoutId);
    final list = List<WorkoutExercise>.of(w.exercises)
      ..add(WorkoutExercise(
        id: _uuid.v4(),
        exerciseId: exerciseId,
        orderIndex: w.exercises.length,
      ));
    await saveWorkout(w.copyWith(exercises: list));
  }

  Future<void> removeExerciseFromWorkout(
      String workoutId, String workoutExerciseId) async {
    final w = _requireWorkout(workoutId);
    final list = w.exercises.where((e) => e.id != workoutExerciseId).toList();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(orderIndex: i);
    }
    await saveWorkout(w.copyWith(exercises: list));
  }

  Future<void> setExerciseNote(
    String workoutId,
    String workoutExerciseId,
    String note,
  ) async {
    final w = _requireWorkout(workoutId);
    final list = List<WorkoutExercise>.of(w.exercises);
    final i = list.indexWhere((e) => e.id == workoutExerciseId);
    if (i < 0) return;
    list[i] = list[i].copyWith(notes: note);
    await saveWorkout(w.copyWith(exercises: list));
  }

  Future<void> reorderExercise(
      String workoutId, int oldIndex, int newIndex) async {
    final w = _requireWorkout(workoutId);
    final list = List<WorkoutExercise>.of(w.exercises);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, list.length - 1);
    final moved = list.removeAt(oldIndex);
    list.insert(target, moved);
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(orderIndex: i);
    }
    await saveWorkout(w.copyWith(exercises: list));
  }

  Future<void> upsertSet(
    String workoutId,
    String workoutExerciseId,
    SetEntry entry,
  ) async {
    final w = _requireWorkout(workoutId);
    final list = List<WorkoutExercise>.of(w.exercises);
    final i = list.indexWhere((e) => e.id == workoutExerciseId);
    if (i < 0) return;

    final sets = List<SetEntry>.of(list[i].sets);
    final si = sets.indexWhere((s) => s.id == entry.id);
    if (si < 0) {
      sets.add(entry.copyWith(setIndex: sets.length + 1));
    } else {
      sets[si] = entry;
    }
    list[i] = list[i].copyWith(sets: _reindex(sets));
    await saveWorkout(w.copyWith(exercises: list));
  }

  Future<void> deleteSet(
    String workoutId,
    String workoutExerciseId,
    String setId,
  ) async {
    final w = _requireWorkout(workoutId);
    final list = List<WorkoutExercise>.of(w.exercises);
    final i = list.indexWhere((e) => e.id == workoutExerciseId);
    if (i < 0) return;
    final sets = list[i].sets.where((s) => s.id != setId).toList();
    list[i] = list[i].copyWith(sets: _reindex(sets));
    await saveWorkout(w.copyWith(exercises: list));
  }

  List<SetEntry> _reindex(List<SetEntry> sets) {
    for (var i = 0; i < sets.length; i++) {
      sets[i] = sets[i].copyWith(setIndex: i + 1);
    }
    return sets;
  }

  String newId() => _uuid.v4();

  // ------------------------------------------------------------ settings

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setPillarSuggesting(Pillar p, bool on) async {
    final next = Set<Pillar>.of(_settings.suggestingPillars);
    if (on) {
      next.add(p);
    } else {
      next.remove(p);
    }
    _settings = _settings.copyWith(suggestingPillars: next);
    await _persist();
  }

  /// Applies the bundled Notion snapshot. Existing goals and tasks are
  /// replaced; training data is never touched, because it did not come
  /// from Notion and could not be recovered from there.
  Future<int> importNotionSnapshot() async {
    final snapshot = await NotionSnapshot.load();
    if (snapshot.isEmpty) return 0;

    _goals
      ..clear()
      ..addAll(snapshot.goals);
    _tasks
      ..clear()
      ..addAll(snapshot.tasks);

    if (snapshot.suggestingPillars.isNotEmpty) {
      _settings =
          _settings.copyWith(suggestingPillars: snapshot.suggestingPillars);
    }
    _notionImported = true;

    await _persist();
    return snapshot.goals.length + snapshot.tasks.length;
  }

  /// Replaces the exercise library and the workout templates with the
  /// bundled cycle. Sessions you have already logged are left alone —
  /// exercises are matched by name, so nothing in your history is
  /// orphaned and no chart loses its line.
  Future<int> importTrainingPlan() async {
    final plan = await TrainingPlan.load();
    if (plan.isEmpty) return 0;

    // plan id -> the id the library will actually use
    final remap = <String, String>{};
    final library = <Exercise>[];

    for (final planned in plan.exercises) {
      final matches = _exercises.where((x) =>
          x.name.toLowerCase() == planned.name.toLowerCase() &&
          x.type == planned.type);
      if (matches.isEmpty) {
        remap[planned.id] = planned.id;
        library.add(planned);
      } else {
        final existing = matches.first;
        remap[planned.id] = existing.id;
        library.add(existing.copyWith(name: planned.name, isArchived: false));
      }
    }

    // Anything the old plan used that history still references survives,
    // archived, so past sessions keep their names.
    for (final old in _exercises) {
      if (library.any((k) => k.id == old.id)) continue;
      if (exerciseHasHistory(old.id)) {
        library.add(old.copyWith(isArchived: true));
      }
    }

    _exercises
      ..clear()
      ..addAll(library);

    _workouts.removeWhere((w) => w.isTemplate);
    for (final template in plan.templates) {
      _workouts.add(
        template.copyWith(
          exercises: [
            for (final we in template.exercises)
              WorkoutExercise(
                id: _uuid.v4(),
                exerciseId: remap[we.exerciseId] ?? we.exerciseId,
                orderIndex: we.orderIndex,
                notes: we.notes,
              ),
          ],
        ),
      );
    }

    _trainingPlanImported = true;
    await _persist();
    return plan.templates.length;
  }

  String exportJson() => _store.exportJson(_document());

  Future<void> eraseEverything() async {
    _tasks.clear();
    _goals.clear();
    _workouts.clear();
    _exercises.clear();
    _settings = AppSettings();
    _notionImported = false;
    _trainingPlanImported = false;
    await _store.save(_document());
    notifyListeners();
  }

  // ----------------------------------------------------------- lifecycle

  Future<void> load() async {
    final doc = await _store.load();
    _applyDocument(doc);

    // First launch on a clean install: start from the real workspace
    // rather than an empty shell. A saved empty document is intentional.
    if (doc.isEmpty && !_notionImported) {
      try {
        await importNotionSnapshot();
      } on Exception {
        // A missing or malformed asset must never stop the app opening.
        _notionImported = true;
      }
    }

    if (doc.isEmpty && _exercises.isEmpty && !_trainingPlanImported) {
      try {
        await importTrainingPlan();
      } on Exception {
        _trainingPlanImported = true;
      }
    }

    _ready = true;
    notifyListeners();

    _storeSubscription = _store.changes.listen((remoteDocument) {
      _applyDocument(remoteDocument);
      notifyListeners();
    });
  }

  void _applyDocument(Map<String, Object?> doc) {
    _tasks
      ..clear()
      ..addAll(_list(doc['tasks']).map(Task.fromJson));
    _goals
      ..clear()
      ..addAll(_list(doc['goals']).map(Goal.fromJson));
    _workouts
      ..clear()
      ..addAll(_list(doc['workouts']).map(Workout.fromJson));
    _exercises
      ..clear()
      ..addAll(_list(doc['exercises']).map(Exercise.fromJson));

    final s = doc['settings'];
    _settings = s is Map
        ? AppSettings.fromJson(Map<String, Object?>.from(s))
        : AppSettings();


    _notionImported = (doc['notion_imported'] as bool?) ?? false;
    _trainingPlanImported = (doc['training_plan_imported'] as bool?) ?? false;
  }

  Map<String, Object?> _document() => {
        'version': 1,
        'tasks': _tasks.map((t) => t.toJson()).toList(),
        'goals': _goals.map((g) => g.toJson()).toList(),
        'workouts': _workouts.map((w) => w.toJson()).toList(),
        'exercises': _exercises.map((e) => e.toJson()).toList(),
        'settings': _settings.toJson(),
        'notion_imported': _notionImported,
        'training_plan_imported': _trainingPlanImported,
      };

  Future<void> _persist() async {
    notifyListeners();
    await _store.save(_document());
  }

  static List<Map<String, Object?>> _list(Object? v) =>
      ((v as List?) ?? const [])
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList();

  void _notifySyncStatusChanged() => notifyListeners();

  @override
  void dispose() {
    final subscription = _storeSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    _store.syncStatus.removeListener(_notifySyncStatusChanged);
    _store.syncMessage.removeListener(_notifySyncStatusChanged);
    _store.dispose();
    super.dispose();
  }
}

String _defaultTitle(WorkoutType type) => switch (type) {
      WorkoutType.strength => 'Strength session',
      WorkoutType.running => 'Run',
      WorkoutType.skills => 'Skills session',
      WorkoutType.conditioning => 'HYROX session',
    };
