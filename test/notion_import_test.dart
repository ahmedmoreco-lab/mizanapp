import 'dart:convert';
import 'dart:io';

import 'package:ahmed_os/models/enums.dart';
import 'package:ahmed_os/models/goal.dart';
import 'package:ahmed_os/models/pillar.dart';
import 'package:ahmed_os/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Goal> goals;
  late List<Task> tasks;
  late Map<String, Object?> doc;

  setUpAll(() {
    final raw = File('assets/data/notion_import.json').readAsStringSync();
    doc = Map<String, Object?>.from(jsonDecode(raw) as Map);
    List<Map<String, Object?>> rows(Object? v) => (v! as List)
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
    goals = rows(doc['goals']).map(Goal.fromJson).toList();
    tasks = rows(doc['tasks']).map(Task.fromJson).toList();
  });

  test('the snapshot parses into real models', () {
    expect(goals, hasLength(7));
    expect(tasks, hasLength(18));
    for (final g in goals) {
      expect(g.title.trim(), isNotEmpty);
      expect(g.measure.trim(), isNotEmpty, reason: 'measure came from Notion');
      expect(g.whyItMatters, isEmpty,
          reason: 'why it matters is never auto-filled');
    }
  });

  test('every task points at a goal that exists', () {
    final ids = goals.map((g) => g.id).toSet();
    for (final t in tasks) {
      expect(t.goalId, isNotNull);
      expect(ids, contains(t.goalId));
    }
  });

  test('a task carries the pillar of its goal', () {
    final byId = {for (final g in goals) g.id: g};
    for (final t in tasks) {
      expect(t.pillar, byId[t.goalId]!.pillar, reason: t.title);
    }
  });

  test('the four skill goals were remapped off Work', () {
    final byTitle = {for (final g in goals) g.title: g.pillar};
    expect(byTitle['Claude AI mastery & applied agents'], Pillar.learning);
    expect(byTitle['Sales, connection & persuasion skills'], Pillar.learning);
    expect(byTitle['Financial literacy, saving & investing'], Pillar.learning);
    expect(byTitle['Content creation & social media influence'], Pillar.content);
  });

  test('finished tasks carry a completion time, open ones do not', () {
    for (final t in tasks) {
      if (t.done) {
        expect(t.completedAt, isNotNull, reason: t.title);
      } else {
        expect(t.completedAt, isNull, reason: t.title);
      }
    }
    expect(tasks.where((t) => t.done), hasLength(8));
  });

  test('nothing finished is still pinned to today', () {
    expect(tasks.where((t) => t.isTodayFocus && t.done), isEmpty);
    expect(tasks.where((t) => t.isTodayFocus), hasLength(4));
  });

  test('priorities survive the import', () {
    expect(tasks.where((t) => t.priority == Priority.high), isNotEmpty);
    expect(tasks.every((t) => t.priority != null), isTrue);
  });

  test('ids are unique', () {
    expect(goals.map((g) => g.id).toSet(), hasLength(goals.length));
    expect(tasks.map((t) => t.id).toSet(), hasLength(tasks.length));
  });

  test('Content is switched on because it now holds a goal', () {
    final on = (doc['suggesting_pillars']! as List).cast<String>().toSet();
    expect(on, contains('content'));
    expect(on, contains('learning'));
    expect(on, isNot(contains('rest')));
    expect(on, isNot(contains('personal')));
    // every pillar that holds a goal must be able to surface on Home
    for (final g in goals) {
      expect(on, contains(g.pillar.key), reason: g.title);
    }
  });
}
