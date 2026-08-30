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
      'focus': <String, Object?>{
        'date': null,
        'pillars': <Object?>[],
      },
    };

class _FakeStore implements DocumentStore {
  _FakeStore(this.document);

  Map<String, Object?> document;
  final _status = ValueNotifier(SyncStatus.synced);
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
  Future<void> clear() async => document = <String, Object?>{};

  @override
  void dispose() {
    _status.dispose();
    unawaited(_changes.close());
  }

  @override
  String exportJson(Map<String, Object?> document) => document.toString();

  @override
  Future<Map<String, Object?>> load() async => document;

  @override
  Future<void> save(Map<String, Object?> next) async => document = next;
}
