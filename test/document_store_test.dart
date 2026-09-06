import 'dart:async';

import 'package:ahmed_os/data/local_store.dart';
import 'package:ahmed_os/models/app_settings.dart';
import 'package:ahmed_os/models/task.dart';
import 'package:ahmed_os/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the Home agenda', () {
    Future<AppState> stateWith(List<Map<String, Object?>> tasks) async {
      final state = AppState(
        store: _FakeStore({..._emptyDocument(), 'tasks': tasks}),
      );
      await state.load();
      return state;
    }

    test('today holds what is due today and what is already late', () async {
      final state = await stateWith([
        _task('due-today', due: _day(0)),
        _task('late', due: _day(-3)),
        _task('later', due: _day(2)),
        _task('loose'),
        _task('finished', due: _day(0), done: true, completedAt: _day(0)),
      ]);
      addTearDown(state.dispose);

      expect(state.todayTasks.map((t) => t.id), ['late', 'due-today']);
      expect(state.doneToday.map((t) => t.id), ['finished']);
    });

    test('a future task is not on today', () async {
      final state = await stateWith([_task('later', due: _day(2))]);
      addTearDown(state.dispose);
      expect(state.todayTasks, isEmpty);
    });

    test('loose means undated and unfinished, nothing else', () async {
      final state = await stateWith([
        _task('loose-one'),
        _task('loose-two'),
        _task('dated', due: _day(4)),
        _task('done-loose', done: true, completedAt: _day(-1)),
      ]);
      addTearDown(state.dispose);

      expect(state.looseTasks.map((t) => t.id),
          containsAll(<String>['loose-one', 'loose-two']));
      expect(state.looseTasks, hasLength(2));
    });

    test('a day carries its own tasks and counts only the open ones',
        () async {
      final state = await stateWith([
        _task('a', due: _day(3)),
        _task('b', due: _day(3), done: true, completedAt: _day(3)),
        _task('c', due: _day(4)),
      ]);
      addTearDown(state.dispose);

      expect(state.tasksOn(_day(3)).map((t) => t.id), ['a', 'b']);
      expect(state.openCountOn(_day(3)), 1);
      expect(state.openCountOn(_day(9)), 0);
    });

    test('a task finished yesterday is not on today', () async {
      final state = await stateWith([
        _task('old', due: _day(-1), done: true, completedAt: _day(-1)),
      ]);
      addTearDown(state.dispose);
      expect(state.doneToday, isEmpty);
      expect(state.todayTasks, isEmpty);
    });
  });

  test('account caches are separated by user id', () async {
    SharedPreferences.setMockInitialValues({});
    final first = LocalStore.forUser('first-user');
    final second = LocalStore.forUser('second-user');

    await first.save({'owner': 'first'});
    await second.save({'owner': 'second'});

    expect(await first.load(), {'owner': 'first'});
    expect(await second.load(), {'owner': 'second'});

    first.dispose();
    second.dispose();
  });

  test('a deliberately emptied document does not reload starter data',
      () async {
    final store = _FakeStore(_emptyDocument());
    final state = AppState(store: store);

    await state.load();

    expect(state.tasks, isEmpty);
    expect(state.goals, isEmpty);
    expect(state.workouts, isEmpty);
    expect(state.exercises, isEmpty);
    state.dispose();
  });

  test('a cloud change is applied while the app is open', () async {
    final store = _FakeStore(_emptyDocument());
    final state = AppState(store: store);
    await state.load();

    store.push({
      ..._emptyDocument(),
      'tasks': [
        Task(
          id: 'remote-task',
          title: 'Added from phone',
          createdAt: DateTime(2026, 8, 30),
        ).toJson(),
      ],
    });
    await pumpEventQueue();

    expect(state.tasks.single.title, 'Added from phone');
    state.dispose();
  });
}

Map<String, Object?> _emptyDocument() => {
      'version': 1,
      'tasks': <Object?>[],
      'goals': <Object?>[],
      'workouts': <Object?>[],
      'exercises': <Object?>[],
      'settings': AppSettings().toJson(),
      'notion_imported': false,
      'training_plan_imported': false,
    };


DateTime _day(int offsetFromToday) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .add(Duration(days: offsetFromToday));
}

Map<String, Object?> _task(
  String id, {
  DateTime? due,
  bool done = false,
  DateTime? completedAt,
  String? pillar,
}) =>
    {
      'id': id,
      'title': id,
      'pillar': pillar,
      'goal_id': null,
      'is_today_focus': 0,
      'done': done ? 1 : 0,
      'priority': null,
      'due_date': due?.millisecondsSinceEpoch,
      'notes': '',
      'created_at': _day(-10).millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };

class _FakeStore implements DocumentStore {
  _FakeStore(this.document);

  Map<String, Object?> document;
  final _status = ValueNotifier(SyncStatus.synced);
  final _message = ValueNotifier<String?>(null);
  final _changes = StreamController<Map<String, Object?>>.broadcast();

  void push(Map<String, Object?> next) {
    document = next;
    _changes.add(next);
  }

  @override
  String? get accountEmail => 'test@example.com';

  @override
  Stream<Map<String, Object?>> get changes => _changes.stream;

  @override
  bool get isCloudBacked => true;

  @override
  ValueListenable<SyncStatus> get syncStatus => _status;

  @override
  ValueListenable<String?> get syncMessage => _message;

  @override
  Future<void> clear() async => document = <String, Object?>{};

  @override
  void dispose() {
    _status.dispose();
    _message.dispose();
    unawaited(_changes.close());
  }

  @override
  String exportJson(Map<String, Object?> document) => document.toString();

  @override
  Future<Map<String, Object?>> load() async => document;

  @override
  Future<void> save(Map<String, Object?> next) async => document = next;
}
